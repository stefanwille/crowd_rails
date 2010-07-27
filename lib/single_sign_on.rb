class Crowd
  
  # The single sign on (SSO) functionality for Atlassian Crowd as a mixin module. 
  # 
  # To use this module, include it in your Rails ApplicationController class.
  # The module uses controller methods such as cookies, session, params.  
  #
  # Author::    Stefan Wille
  # Copyright:: Copyright (c) 2010 Stefan Wille
  # License::   BSD
  
  module SingleSignOn
      
    # Returns whether the user is already authenticated.
    def crowd_authenticated?
      crowd_logger.info "Crowd: All cookies: #{cookies.inspect}"
      
      token = crowd_token
      if token.blank?
        crowd_logger.info "Crowd: No token"
        return false
      end
      
      if crowd_authentication_cached?
        crowd_logger.info "Crowd: Authentication is cached"
        return true
      else 
        crowd_logger.info "Crowd: Authentication is not cached"
      end      
      
      if Crowd.is_valid_principal_token?(token, crowd_validation_factors)
        crowd_logger.info "Crowd: Token is valid"      
        crowd_mark_session_as_authenticated(token)
        return true
      else 
        crowd_logger.info "Crowd: Token is invalid"      
        return false
      end
    end
      
    # Authenticates the user with the given user name and password and 
    # marks the user as authenticated on success.
    # 
    # Returns the crowd token on success, false on failure.
    
    def crowd_authenticate(user_name, password)      
      crowd_authenticate!(user_name, password)
    rescue Crowd::AuthenticationException => e
      false
    end

    # Same as #crowd_authenticate, but raises an AuthenticationException on failure.
    
    def crowd_authenticate!(user_name, password)
      crowd_logger.info "Crowd: Authenticating user #{user_name}"
      token = Crowd.authenticate_principal(user_name, password, crowd_validation_factors)
      crowd_mark_session_as_authenticated(token)      
      crowd_logger.info "Crowd: Authentication successful, token #{token}"
      token
    end  

    # Returns the current users display name.
    
    def crowd_current_user_display_name
      user = crowd_current_user
      user && user[:attributes][:displayName]
    end

    # Returns the current user, as seen by crowd.
    
    def crowd_current_user
      crowd_token && Crowd.find_principal_by_token(crowd_token)
    end

    # Returns the crowd token or nil.
    
    def crowd_token
      crowd_logger.info "params token: #{params[Crowd.crowd_cookie_tokenkey]}"
      crowd_logger.info "cookies token: #{cookies[Crowd.crowd_cookie_tokenkey]}"
      crowd_logger.info "session token: #{session[Crowd.crowd_session_tokenkey]}"
      token = params[Crowd.crowd_cookie_tokenkey] || cookies[Crowd.crowd_cookie_tokenkey] || session[Crowd.crowd_session_tokenkey]
      crowd_logger.info "token = #{token}"
      token
    end

    # Marks the user as unauthenticated

    def crowd_log_out
      crowd_logger.info "Crowd: log out"
      crowd_update_token(nil)
      crowd_clear_cache
    end
        
    private

    # Returns the client's validation factors. 
    # Validation factors are essential for interoperation with Atlassian's client library!

    def crowd_validation_factors
      validation_factors = { 'remote_address' => crowd_remote_address }

      if Crowd.crowd_validation_factors_need_user_agent
        validation_factors['User-Agent'] = crowd_user_agent
      end
            
      forwarded_for = request.env['X-Forwarded-For']
      if forwarded_for.present? && forwarded_for != request.remote_ip
        validation_factors['X-Forwarded-For'] = forwarded_for
      end

      crowd_logger.info "Crowd validation_factors: #{validation_factors.inspect}"
      
      validation_factors
    end
    
    # Returns the client's IP address. 
    
    def crowd_remote_address
      # For localhost, Crowd wants the IPv6 address.
      (request.remote_ip == '127.0.0.1' || request.remote_ip == '0.0.0.0') ? '0:0:0:0:0:0:0:1%0' : request.remote_ip
    end
    

    # Returns the client's user agent. 

    def crowd_user_agent
      request.env['HTTP_USER_AGENT']
    end

    # Whether a successful authentication is in cache.
    
    def crowd_authentication_cached?
      last_validation = session[Crowd.crowd_session_lastvalidation]

      if last_validation.present? && crowd_caching_enabled?
        time_diff = crowd_time_diff_in_minutes(Time.now,  last_validation)
        return time_diff < Crowd.crowd_session_validationinterval
      else
        return false
      end      
    end
    
    # Marks the session as successfully authenticated and sets the SSO cookie.
    
    def crowd_mark_session_as_authenticated(token)
      crowd_update_token(token)
      if crowd_caching_enabled?
        crowd_logger.info "Crowd: Caching authentication"
        session[Crowd.crowd_session_lastvalidation] = Time.now
      end
    end    
        
    def crowd_update_token(token)
      session[Crowd.crowd_session_tokenkey] = token
      cookies[Crowd.crowd_cookie_tokenkey] = { :value	=> token, :domain => crowd_cookie_domain, :path => "/", :secure => Crowd.get_cookie_info.secure }
    end
    
    def crowd_clear_cache
      session[Crowd.crowd_session_lastvalidation] = nil
    end

    def crowd_cookie_domain
      cookie_domain = Crowd.get_cookie_info.domain
      if cookie_domain
        cookie_domain
      else
        request.domain ? '.' + request.domain : nil
      end
    end

    # Returns the difference between two timestamps in minutes.
    def crowd_time_diff_in_minutes(first_time, second_time)
      (first_time - second_time).round / 1.minute
    end
    
    # Whether caching of successful authentication is enabled.
    def crowd_caching_enabled?
      Crowd.crowd_session_validationinterval > 0
    end    
    
    # Logger used for debugging
    def crowd_logger
      unless @crowd_logger
        @crowd_logger = Logger.new(STDOUT).
        @crowd_logger.level = Logger::WARN
      end
      @crowd_logger
    end
  end  
end


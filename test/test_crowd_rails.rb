#!/usr/bin/env ruby

require 'helper'

gem 'rails', '~>2.3.0'
#gem 'mocha', '~>0.9.7'
#require 'logger'
#gem 'rspec'
gem 'crowd-stefanwille', '~> 0.5.10'
#require 'crowd_rails'
require 'crowd'



require 'test/unit'
require 'active_support'
require 'action_controller'
require 'action_view/test_case'

$:.unshift File.dirname(__FILE__) + '/../lib'
#require File.dirname(__FILE__) + '/../init.rb'

RAILS_ROOT = '.' unless defined? RAILS_ROOT
RAILS_ENV = 'test' unless defined? RAILS_ENV

#ActionController::Routing::Routes.reload rescue nil


include Crowd::UserAttributeKeys

class TestController < ActionController::Base
  include Crowd::SingleSignOn  
  
  def index
    render :text => ""
  end
end

class TestControllerTest < ActionController::TestCase
  def setup
    Crowd.crowd_url = 'http://127.0.0.1:8095/crowd/services/SecurityServer'
    Crowd.crowd_app_name = 'soaptest'
    Crowd.crowd_app_pword = 'soaptest'
    Crowd.authenticate_application    
    Crowd.add_principal('unittest','password','unit test user', true, { 'mail' => 'unittest@unittest.com', FIRSTNAME => 'Unit', LASTNAME => 'Test' })
    @controller.logger = Logger.new(STDOUT)
    @controller.session = {}
    get :index
  end
  
  def teardown
   Crowd.remove_principal('unittest')
  end
  
  # Replace this with your real tests.
  # test "#crowd_authenticate should authenticate a user and return the crowd token" do
  #   @controller.crowd_authenticate('unittest', 'password').should_not be_nil
  #   @controller.__send__(:crowd_token).should_not be_nil
  #   # @controller.crowd_authenticated?.should be_true
  # end
end

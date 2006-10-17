ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

module LoginEngine
  config :salt, "test-salt", :force
end

module ChipAccounting

end

class Test::Unit::TestCase
  fixtures :users, :roles, :permissions, :users_roles, :permissions_roles,
           :site_config

  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  self.use_transactional_fixtures = false

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = true

  # Add more helper methods to be used by all tests here...
  def assert_errors
    assert_tag error_message_field
  end
  
  def assert_no_errors
    assert_no_tag error_message_field
  end

  def error_message_field
    # {:tag => "div", :attributes => { :class => "fieldWithErrors" }} ||
    {:tag => "div", :attributes => { :class => "errorExplanation" }}
  end

  def assert_flash_warning
    assert_tag flash_warning_field
  end
  
  def assert_no_flash_warning
    assert_no_tag flash_warning_field
  end
  
  def flash_warning_field
    {:tag => "p", :attributes => { :style => "color: red" }}
  end
  
  def assert_text_field_hidden(field_id)
    assert_tag text_field(field_id)
  end
  
  def assert_text_field_visible(field_id)
    assert_no_tag text_field(field_id)
  end
  
  def text_field(field_id)
    {:tag => "input", :attributes => { :id => "#{field_id}", :type => "hidden" }}
  end

  # login as admin, necessary to reach pages for testing
  def login_as_admin
    controller_bak = @controller
    @controller = UserController.new
    post :login, :user => {:login => 'admin', :password => 'atest'}
    #assert_not_nil(session[:user])
    #user = User.find(session[:user].id)
    #assert_equal user.login, "admin", "Login name should match session name"
    
    @controller = controller_bak
  end

  # login as a customer to test customer-specific code
  def login_as_customer
    controller_bak = @controller
    @controller = UserController.new
    
    post :login, :user => {:login => 'customer', :password => 'atest'}
    
    @controller = controller_bak
  end

end

def using_Mysql?
  if(ActiveRecord::Base.connection.adapter_name == "MySQL")
    return true;
  else
    return false;
  end
end

class Fixtures
    alias :original_delete_existing_fixtures :delete_existing_fixtures
    alias :original_insert_fixtures :insert_fixtures

    def delete_existing_fixtures
      if using_Mysql?
        @connection.update "SET FOREIGN_KEY_CHECKS = 0", 'Fixtures deactivate foreign key checks.';
        original_delete_existing_fixtures
        @connection.update "SET FOREIGN_KEY_CHECKS = 1", 'Fixtures activate foreign key checks.';
      else
        original_delete_existing_fixtures
      end
    end

    def insert_fixtures
      if using_Mysql?
        @connection.update "SET FOREIGN_KEY_CHECKS = 0", 'Fixtures deactivate foreign key checks.';
        original_insert_fixtures
        @connection.update "SET FOREIGN_KEY_CHECKS = 1", 'Fixtures activate foreign key checks.';
      else
        original_insert_fixtures
      end
    end
end

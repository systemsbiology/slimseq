require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead.
  # Then, you can remove it from this and the functional test.
  include AuthenticatedTestHelper
  fixtures :users

  def test_should_create_user
    assert_difference 'User.count' do
      user = create_user
      assert !user.new_record?, "#{user.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_login
    assert_no_difference 'User.count' do
      u = create_user(:login => nil)
      assert u.errors.on(:login)
    end
  end

  def test_should_not_require_password
    assert_difference 'User.count' do
      u = create_user(:password => nil)
      assert !u.new_record?, "#{u.errors.full_messages.to_sentence}"
    end
  end

  def test_should_not_require_password_confirmation_without_password
    assert_difference 'User.count' do
      u = create_user(:password => nil, :password_confirmation => nil)
      assert !u.new_record?, "#{u.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_email
    assert_no_difference 'User.count' do
      u = create_user(:email => nil)
      assert u.errors.on(:email)
    end
  end

  def test_should_require_firstname
    assert_no_difference 'User.count' do
      u = create_user(:firstname => nil)
      assert u.errors.on(:firstname)
    end    
  end

  def test_should_require_lastname
    assert_no_difference 'User.count' do
      u = create_user(:lastname => nil)
      assert u.errors.on(:lastname)
    end    
  end
  
  def test_should_require_unique_name
    assert_no_difference 'User.count' do
      u = create_user(:firstname => "Joe",
                      :lastname => "Customer")
      assert u.errors
    end    
  end
  
  def test_should_reset_password
    users(:customer_user).update_attributes(:password => 'new password', :password_confirmation => 'new password')
    assert_equal users(:customer_user), User.authenticate('customer', 'new password')
  end

  def test_should_not_rehash_password
    users(:customer_user).update_attributes(:login => 'customer2')
    assert_equal users(:customer_user), User.authenticate('customer2', 'atest')
  end

  def test_should_authenticate_user
    assert_equal users(:customer_user), User.authenticate('customer', 'atest')
  end

  def test_should_set_remember_token
    users(:customer_user).remember_me
    assert_not_nil users(:customer_user).remember_token
    assert_not_nil users(:customer_user).remember_token_expires_at
  end

  def test_should_unset_remember_token
    users(:customer_user).remember_me
    assert_not_nil users(:customer_user).remember_token
    users(:customer_user).forget_me
    assert_nil users(:customer_user).remember_token
  end

  def test_should_remember_me_for_one_week
    before = 1.week.from_now.utc
    users(:customer_user).remember_me_for 1.week
    after = 1.week.from_now.utc
    assert_not_nil users(:customer_user).remember_token
    assert_not_nil users(:customer_user).remember_token_expires_at
    assert users(:customer_user).remember_token_expires_at.between?(before, after)
  end

  def test_should_remember_me_until_one_week
    time = 1.week.from_now.utc
    users(:customer_user).remember_me_until time
    assert_not_nil users(:customer_user).remember_token
    assert_not_nil users(:customer_user).remember_token_expires_at
    assert_equal users(:customer_user).remember_token_expires_at, time
  end

  def test_should_remember_me_default_two_weeks
    before = 2.weeks.from_now.utc
    users(:customer_user).remember_me
    after = 2.weeks.from_now.utc
    assert_not_nil users(:customer_user).remember_token
    assert_not_nil users(:customer_user).remember_token_expires_at
    assert users(:customer_user).remember_token_expires_at.between?(before, after)
  end

protected
  def create_user(options = {})
    User.create({ :login => 'quire',
                  :email => 'quire@example.com',
                  :password => 'quire',
                  :password_confirmation => 'quire',
                  :firstname => 'Quentin',
                  :lastname => 'Quire',
                  :role => 'customer'
                }.merge(options))
  end
end

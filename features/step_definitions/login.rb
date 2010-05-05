Given /I am logged in as a customer/i do
  # Handle slimcore vs. slimsolo authorizers
  if(Rails::Plugin::AUTHORIZER == "slimcore")
    User.create(
      :firstname => "Test",
      :lastname => "User",
      :email => "testuser@example.com",
      :login => "testuser"
    )
    
    visits "/sessions/new"  
    fills_in("username", :with => AppConfig.test_login)  
    fills_in("password", :with => AppConfig.test_password)  
    clicks_button("LOGIN")  
  else
    @user = User.create(:firstname => "Jim",  
      :lastname => "User",
      :email => "jim@example.com",
      :login => "the_login",  
      :password => "password",  
      :password_confirmation => "password")  
    visits "/sessions/new"  
    fills_in("login", :with => AppConfig.test_login)  
    fills_in("password", :with => AppConfig.test_password)  
    clicks_button("Log in")  
  end
end  

Given /I am logged in as a staff member/i do
  @user = User.create(:firstname => "Staff",  
    :lastname => "User",
    :email => "staff.com",
    :login => "the_login",  
    :password => "password",  
    :password_confirmation => "password",
    :role => "staff")
  visits "/sessions/new"  
  fills_in("login", :with => "the_login")  
  fills_in("password", :with => "password")  
  clicks_button("Log in")  
end  

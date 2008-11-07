Given /I am logged in as a customer/i do
  @user = User.create(:firstname => "Jim",  
    :lastname => "User",
    :email => "jim@example.com",
    :login => "the_login",  
    :password => "password",  
    :password_confirmation => "password")  
  visits "/sessions/new"  
  fills_in("login", :with => "the_login")  
  fills_in("password", :with => "password")  
  clicks_button("Log in")  
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

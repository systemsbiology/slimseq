def login_as_user
  @current_user = mock_model(User)     
  User.should_receive(:find).any_number_of_times.and_return(@current_user)
  User.should_receive(:find_by_id).any_number_of_times.and_return(@current_user)
  User.should_receive(:staff_or_admin?).any_number_of_times.and_return(false)
  request.session[:user_id] = @current_user.id
  request.session[:user] = @current_user
end

def login_as_staff
  @current_user = mock_model(User)     
  User.should_receive(:find).any_number_of_times.and_return(@current_user)
  User.should_receive(:find_by_id).any_number_of_times.and_return(@current_user)
  @current_user.should_receive(:staff_or_admin?).any_number_of_times.and_return(true)
  request.session[:user_id] = @current_user.id
  request.session[:user] = @current_user
end

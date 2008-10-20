def login_as_user
  @current_user = mock_model(User)     
  User.should_receive(:find).any_number_of_times.and_return(@current_user)
  User.should_receive(:find_by_id).any_number_of_times.and_return(@current_user)
  request.session[:user_id] = @current_user.id
  request.session[:user] = @current_user
end

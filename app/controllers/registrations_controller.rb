class RegistrationsController < ApplicationController
  before_filter :login_required
  
  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])

    if @user.save
      redirect_to(users_url)
      flash[:notice] = "User successfully registered!"
    else
      render :action => 'new'
    end
  end

end

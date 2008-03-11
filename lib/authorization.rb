module Authorization
  def staff_or_admin_required
    current_user.staff_or_admin? || insufficient_privileges
  end
  
  def admin_required
    current_user.admin? || insufficient_privileges
  end
  
  def insufficient_privileges
    redirect_to :controller => "welcome"
  end
end

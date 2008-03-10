class SiteConfigController < ApplicationController
  before_filter :login_required
  before_filter :admin_required
  
  def edit
    @site_config = SiteConfig.find(1)
  end

  def update
    @site_config = SiteConfig.find(1)

    begin
      if @site_config.update_attributes(params[:site_config])
        flash[:notice] = 'Site configuration was successfully updated.'
        redirect_to :action => 'edit'
      else
        render :action => 'edit'
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified the site configuration."
      @site_config = SiteConfig.find(params[:id])
      render :action => 'edit'
    end
  end
end

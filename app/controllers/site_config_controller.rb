class SiteConfigController < ApplicationController

  def edit
    @site_config = SiteConfig.find(1)
  end

  def update
    @site_config = SiteConfig.find(1)
    if @site_config.update_attributes(params[:site_config])
      flash[:notice] = 'Site configuration was successfully updated.'
      redirect_to :action => 'edit'
    else
      render :action => 'edit'
    end
  end
end

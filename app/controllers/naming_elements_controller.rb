class NamingElementsController < ApplicationController

  def list_for_naming_scheme
    if params[:naming_scheme_id] != nil
      @naming_scheme = NamingScheme.find(params[:naming_scheme_id])
      
      # store current naming scheme
      session[:naming_scheme_id] = @naming_scheme.id
    elsif session[:naming_scheme_id] != nil
      @naming_scheme = NamingScheme.find(session[:naming_scheme_id])    
    end
    
    if @naming_scheme != nil
      @naming_elements = NamingElement.find(:all,
                                            :conditions => ["naming_scheme_id = ?", @naming_scheme.id],
                                            :order => "element_order ASC")
    else
      redirect_to :controller => 'naming_schemes', :action => 'list'
    end
  end

  def new
    naming_scheme_id = params[:naming_scheme_id]
    @naming_element_list = NamingElement.find(:all,
                             :conditions => ["naming_scheme_id = ?", naming_scheme_id],
                             :order => "element_order ASC")
    @naming_element = NamingElement.new
    @naming_element.naming_scheme_id = naming_scheme_id
  end

  def create
    @naming_element = NamingElement.new(params[:naming_element])
    if @naming_element.save
      flash[:notice] = 'Naming element was successfully created.'
      redirect_to :action => 'list_for_naming_scheme', :naming_scheme_id => @naming_element.naming_scheme_id
    else
      render :action => 'new'
    end
  end

  def edit
    naming_scheme_id = params[:naming_scheme_id]
    @naming_element_list = NamingElement.find(:all,
                             :conditions => ["naming_scheme_id = ?", naming_scheme_id],
                             :order => "element_order ASC")
    @naming_element = NamingElement.find(params[:id])
  end

  def update
    @naming_element = NamingElement.find(params[:id])
    
    begin
      if @naming_element.update_attributes(params[:naming_element])
        flash[:notice] = 'Naming element was successfully updated.'
        redirect_to :action => 'list_for_naming_scheme', :id => @naming_element
      else
        render :action => 'edit'
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this naming element."
      @naming_element = NamingElement.find(params[:id])
      render :action => 'edit'
    end
  end

  def destroy
    NamingElement.find(params[:id]).destroy
    redirect_to :action => 'list_for_naming_scheme'
  end

end

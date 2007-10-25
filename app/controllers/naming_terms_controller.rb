class NamingTermsController < ApplicationController

  def list_for_naming_element
    @naming_element = NamingElement.find(params[:id])
    @naming_terms = NamingTerm.find(:all, :conditions => ["naming_element_id = ?", @naming_element.id])
    
    # for new naming term form
    @naming_term = NamingTerm.new(:naming_element_id => @naming_element.id)
  end

  def create
    @naming_term = NamingTerm.new(params[:naming_term])

    if @naming_term.save
      flash[:notice] = 'Naming term was successfully created.'
      redirect_to :action => 'list_for_naming_element', :id => @naming_term.naming_element_id
    else
      render :action => 'list_for_naming_element', :id => @naming_term.naming_element_id
    end
  end

  def edit
    @naming_term = NamingTerm.find(params[:id])
  end

  def update
    @naming_term = NamingTerm.find(params[:id])
    
    begin
      if @naming_term.update_attributes(params[:naming_term])
        flash[:notice] = 'Naming term was successfully updated.'
        redirect_to :action => 'list_for_naming_element', :id => @naming_term.naming_element_id
      else
        render :action => 'edit'
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this naming term."
      @naming_term = NamingTerm.find(params[:id])
      render :action => 'edit'
    end
  end

  def destroy
    term = NamingTerm.find(params[:id])
    naming_element_id = term.naming_element.id
  
    term.destroy
    redirect_to :action => 'list_for_naming_element', :id => naming_element_id    
  end

end

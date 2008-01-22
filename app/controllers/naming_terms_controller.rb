class NamingTermsController < ApplicationController

  def list_for_naming_element
    @naming_element = NamingElement.find(params[:id])
    @naming_terms = NamingTerm.find(:all,
                                    :conditions => ["naming_element_id = ?", @naming_element.id],
                                    :order => "term_order ASC")
    
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

  def move_up
    # the naming term that the user wants to move up
    @naming_term_up = NamingTerm.find(params[:id])

    # see if there's a naming term above it
    @naming_term_down = NamingTerm.find(:first, 
      :conditions => ["naming_element_id = ? AND term_order = ?", @naming_term_up.naming_element_id, @naming_term_up.term_order-1 ])

    # moving this term up only makes sense if there's a term above it
    if( @naming_term_down != nil )
      begin
        @naming_term_up.update_attributes(:term_order => @naming_term_down.term_order)
        @naming_term_down.update_attributes(:term_order => @naming_term_down.term_order+1)
        redirect_to :action => 'list_for_naming_element', :id => @naming_term_up.naming_element_id
      rescue ActiveRecord::StaleObjectError
        flash[:warning] = "Unable to update information. Another user has modified this naming term."
        redirect_to :action => 'list_for_naming_element', :id => @naming_term_up.naming_element_id
      end
    else
      flash[:warning] = "This term is already at the top of the list."
      redirect_to :action => 'list_for_naming_element', :id => @naming_term_up.naming_element_id
    end
  end

  def move_down
    # the naming term that the user wants to move up
    @naming_term_down = NamingTerm.find(params[:id])

    # see if there's a naming term above it
    @naming_term_up = NamingTerm.find(:first, 
      :conditions => ["naming_element_id = ? AND term_order = ?", @naming_term_down.naming_element_id, @naming_term_down.term_order+1 ])

    # moving this term up only makes sense if there's a term above it
    if( @naming_term_up != nil )
      begin
        @naming_term_down.update_attributes(:term_order => @naming_term_up.term_order)
        @naming_term_up.update_attributes(:term_order => @naming_term_up.term_order-1)
        redirect_to :action => 'list_for_naming_element', :id => @naming_term_down.naming_element_id
      rescue ActiveRecord::StaleObjectError
        flash[:warning] = "Unable to update information. Another user has modified this naming term."
        redirect_to :action => 'list_for_naming_element', :id => @naming_term_down.naming_element_id
      end
    else
      flash[:warning] = "This term is already at the top of the list."
      redirect_to :action => 'list_for_naming_element', :id => @naming_term_down.naming_element_id
    end
  end

  def destroy
    term = NamingTerm.find(params[:id])
    naming_element_id = term.naming_element.id
  
    term.destroy
    redirect_to :action => 'list_for_naming_element', :id => naming_element_id    
  end

end

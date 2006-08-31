require File.dirname(__FILE__) + '/../test_helper'
require 'hybridizations_controller'

# Re-raise errors caught by the controller.
class HybridizationsController; def rescue_action(e) raise e end; end

class HybridizationsControllerTest < Test::Unit::TestCase
  fixtures :hybridizations, :samples,
           :lab_groups, :chip_types, :organisms, :charge_templates, :charge_sets

  def setup
    @controller = HybridizationsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    # use admin login for all tests for the moment
    login_as_admin
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:hybridizations)
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'
  end

  def test_add
    # use test_new to populate session variables
    get :new
  
    get :add, :selected_samples => { '1' => '1', '2'=>'0', '3' => '0' },
              :submit_hybridizations => {:hybridization_date => "2006-02-13", 
                            :charge_set_id => 1,
                            :charge_template_id => 1}

    assert_response :success
    assert_template 'add'
    
    # this should have populated the session[:hybridizations] array
    # with two Hybridization objects containing appropriate info
    @hybridizations = session[:hybridizations]
    assert_equal 1, @hybridizations.size
    assert_equal Date.new(2006, 2, 13), @hybridizations[0].hybridization_date
    assert_equal 1, @hybridizations[0].chip_number
    assert_equal 1, @hybridizations[0].sample_id
    assert_equal 1, @hybridizations[0].charge_set_id
    assert_equal 1, @hybridizations[0].charge_template_id

    # make sure that only only non-selected samples remain in selection list
    # should have 2 rows (header + 1 samples)
    assert_select "table#available_samples>tr", 2
  end

  def test_add_nothing_selected
    # use test_new to populate session variables
    get :new
  
    get :add, :selected_samples => { '1' => '0', '2'=>'0', '3' => '0' },
              :submit_hybridizations => {:hybridization_date => "2006-02-13", 
                            :charge_set_id => 1,
                            :charge_template_id => 1}

    assert_response :success
    assert_template 'add'
    
    # this should have populated the session[:hybridizations] array
    # with two Hybridization objects containing appropriate info
    @hybridizations = session[:hybridizations]
    assert_equal 0, @hybridizations.size

    # should have 3 rows (header + 2 samples)
    assert_select "table#available_samples>tr", 3
  end

  def test_create_all_tracking_on
    num_hybridizations = Hybridization.count
    num_transactions = ChipTransaction.count
    num_charges = Charge.count

    # use test_add to populate session[:hybridizations] and session[:hybridization_number]
    test_add
                  
    post :create

    assert_response :redirect
    assert_redirected_to :action => 'show'

    # make sure the records made it into the hybridizations table
    assert_equal num_hybridizations + 1,
                 Hybridization.count
                 
    # make sure a chip transaction was recorded
    assert_equal num_transactions + 1,
                 ChipTransaction.count
                 
    # make sure a charge was recorded
    assert_equal num_charges + 1,
                 Charge.count    
  end

  def test_create_bad_gcos_output_path
    # set a nonsensical gcos path
    @site_config = SiteConfig.find(1)
    @site_config.update_attributes(:create_gcos_files => '/path/that/should/not/work')

    num_hybridizations = Hybridization.count
    num_transactions = ChipTransaction.count
    num_charges = Charge.count

    # use test_add to populate session[:hybridizations] and session[:hybridization_number]
    test_add
                  
    post :create

    assert_response :redirect
    assert_redirected_to :action => 'show'
    follow_redirect
    assert_flash_warning

    # make sure the records made it into the hybridizations table
    assert_equal num_hybridizations + 1,
                 Hybridization.count
                 
    # make sure a chip transaction was recorded
    assert_equal num_transactions + 1,
                 ChipTransaction.count
                 
    # make sure a charge was recorded
    assert_equal num_charges + 1,
                 Charge.count    
  end

  def test_create_track_inventory_off
    # turn off inventory tracking
    config = SiteConfig.find(1)
    config.update_attributes(:track_inventory => 0)

    num_hybridizations = Hybridization.count
    num_transactions = ChipTransaction.count
    num_charges = Charge.count

    # use test_add to populate session[:hybridizations] and session[:hybridization_number]
    test_add
                  
    post :create

    assert_response :redirect
    assert_redirected_to :action => 'show'

    # make sure the records made it into the hybridizations table
    assert_equal num_hybridizations + 1,
                 Hybridization.count
                 
    # make sure a chip transaction was recorded
    assert_equal num_transactions, ChipTransaction.count

    # make sure a charge was recorded
    assert_equal num_charges + 1,
                 Charge.count   
  end

  def test_create_charge_tracking_off
    # turn off charge tracking
    config = SiteConfig.find(1)
    config.update_attributes(:track_charges => 0)

    num_hybridizations = Hybridization.count
    num_transactions = ChipTransaction.count
    num_charges = Charge.count

    # use test_add to populate session[:hybridizations] and session[:hybridization_number]
    test_add
                  
    post :create

    assert_response :redirect
    assert_redirected_to :action => 'show'

    # make sure the records made it into the hybridizations table
    assert_equal num_hybridizations + 1,
                 Hybridization.count
                 
    # make sure a chip transaction was recorded
    assert_equal num_transactions + 1,
                 ChipTransaction.count

    # make sure a charge was recorded
    assert_equal num_charges, Charge.count   
  end

  def test_create_duplicate_hybridization_date_number_combo
    num_hybridizations = Hybridization.count

    # enter a new set of hybs
    get :new

    # add one hyb that will have a duplicate hybridization_date/number  
    get :add, :selected_samples => { '1' => '1', '2'=>'0', '3' => '0' },
              :submit_hybridizations => {:hybridization_date => "2006-02-10", 
                            :charge_set_id => 1,
                            :charge_template_id => 1}
    # add another hyb with unique hybridization_date/number
    get :add, :selected_samples => { '2'=>'0', '3' => '1' },
              :submit_hybridizations => {:hybridization_date => "2006-02-12", 
                            :charge_set_id => 1,
                            :charge_template_id => 1}
                       
    post :create

    # make sure it complained
    assert_errors
    assert_response :success
    assert_template 'add'

    # make sure records were not inserted
    assert_equal num_hybridizations, Hybridization.count
  end

  def test_clear
    # use test_add to populate session[:hybridizations] and session[:hybridization_number]
    test_add
    
    post :clear
    
    assert_response :redirect
    assert_redirected_to :action => 'new'
    
    assert_equal 0, session[:hybridizations].size
    assert_equal 0, session[:hybridization_number]
  end

  def test_show
    get :show  

    assert_response :success
    assert_template 'show'
  end

  def test_edit
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:hybridization)
    assert assigns(:hybridization).valid?
  end

  def test_update
    post :update, :id => 1, :hybridization => { :hybridization_date => '2006-02-09' }
    
    hybridization = Hybridization.find(1)
    assert_equal Date.new(2006,2,9), hybridization.hybridization_date
    
    assert_response :redirect
    assert_redirected_to :action => 'list'
  end

  def test_update_locked
    # grab the hybridization we're going to use twice
    hybridization1 = Hybridization.find(1)
    hybridization2 = Hybridization.find(1)
    
    # update it once, which should sucess
    post :update, :id => 1, :hybridization => { :sample_id => 1, 
                                                :lock_version => hybridization1.lock_version }

    # and then update again with stale info, and it should fail
    post :update, :id => 1, :hybridization => { :sample_id => 3, 
                                                :lock_version => hybridization2.lock_version }                                               

    assert_response :success
    assert_template 'edit'
    assert_flash_warning
    
    assert_equal 1, Hybridization.find(1).sample_id
  end

  def test_destroy
    hybridization = Hybridization.find(1)
    sample_id = hybridization.sample_id
    assert_not_nil hybridization

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'
    
    # make sure hybridization doesn't exist
    assert_raise(ActiveRecord::RecordNotFound) {
      Hybridization.find(1)
    }
    
    # sample should have been reset to 'submitted'
    assert_equal 'submitted', Sample.find(sample_id).status
  end

  def test_bulk_destroy
    sample1_id = Hybridization.find(1).sample_id
    sample2_id = Hybridization.find(2).sample_id
  
    post :bulk_destroy, :selected_hybridizations => {'1' => '1', '2' => '1'},
         :commit => "Delete Hybridizations"
    
    assert_response :redirect
    assert_redirected_to :action => 'list'

    # assert that destroys have taken place
    assert_raise(ActiveRecord::RecordNotFound) {
      Hybridization.find(1)
    }
    assert_raise(ActiveRecord::RecordNotFound) {
      Hybridization.find(2)
    }
    
    # assert Samples have been reverted to 'submitted' status
    assert_equal 'submitted', Sample.find(sample1_id).status
    assert_equal 'submitted', Sample.find(sample2_id).status
  end
end

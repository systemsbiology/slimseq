require File.dirname(__FILE__) + '/../test_helper'
require 'hybridizations_controller'

# Re-raise errors caught by the controller.
class HybridizationsController; def rescue_action(e) raise e end; end

class HybridizationsControllerTest < Test::Unit::TestCase
  fixtures :hybridizations, 
           :lab_groups, :chip_types, :organisms, :charge_templates

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

  def test_new_gcos_on_sbeams_on_in_site_config
    get :new

    assert_response :success
    assert_template 'new'
    
    assert_text_field_visible "add_hybs_sbeams_user"
    assert_text_field_visible "add_hybs_sbeams_project"
  end

  def test_new_affy_platform_gcos_on_sbeams_off_in_site_config
    # turn off GCOS support
    config = SiteConfig.find(1)
    config.update_attributes(:create_gcos_files => 1,
                             :using_sbeams => 0)
  
    get :new

    assert_response :success
    assert_template 'new'
    
    assert_text_field_visible "add_hybs_sbeams_user"
    assert_text_field_visible "add_hybs_sbeams_project"
  end

  def test_new_non_affy_platform_gcos_off_in_site_config
    # turn off GCOS support and turn to non-affy mode
    config = SiteConfig.find(1)
    config.update_attributes(:create_gcos_files => 0,
                             :array_platform => "nonaffy")
  
    get :new

    assert_response :success
    assert_template 'new'
    
    assert_text_field_hidden "add_hybs_sbeams_user"
    assert_text_field_hidden "add_hybs_sbeams_project"
  end

  def test_add_sbeams_on_in_site_config
    # use test_new to populate session variables
    get :new
  
    get :add, :add_hybs => {:date => "2006-02-12", :number => 2,
                            :lab_group_id => 1, :chip_type_id => 2,
                            :sbeams_user => "Bob", :sbeams_project => "Bob's Stuff",
                            :charge_template_id => 1}
    
    # this should have populated the session[:hybridizations] array
    # with two Hybridization objects containing appropriate info
    @hybridizations = session[:hybridizations]
    assert_equal 2, @hybridizations.size
    assert_equal Date.new(2006, 2, 12), @hybridizations[0].date
    assert_equal 1, @hybridizations[0].chip_number
    assert_equal 1, @hybridizations[0].lab_group_id
    assert_equal 2, @hybridizations[0].chip_type_id
    assert_equal 2, @hybridizations[0].organism_id
    assert_equal "Bob", @hybridizations[0].sbeams_user
    assert_equal "Bob's Stuff", @hybridizations[0].sbeams_project
    assert_equal 1, @hybridizations[0].charge_template_id
    assert_equal Date.new(2006, 2, 12), @hybridizations[1].date
    assert_equal 2, @hybridizations[1].chip_number
    assert_equal 1, @hybridizations[1].lab_group_id
    assert_equal 2, @hybridizations[1].chip_type_id   
    assert_equal 2, @hybridizations[1].organism_id
    assert_equal "Bob", @hybridizations[1].sbeams_user
    assert_equal "Bob's Stuff", @hybridizations[1].sbeams_project
    assert_equal 1, @hybridizations[1].charge_template_id
    
    assert_response :success
    assert_template 'add'
    
    @hybridizations = session[:hybridizations]
    assert_equal 2, @hybridizations.size
  end

  def test_add_gcos_off_in_site_config
    # turn off GCOS support
    config = SiteConfig.find(1)
    config.update_attributes(:create_gcos_files => 0)

    # use test_new to populate session variables
    get :new
  
    get :add, :add_hybs => {:date => "2006-02-12", :number => 2,
                            :lab_group_id => 1, :chip_type_id => 2,
                            :charge_template_id => 1}
    
    # this should have populated the session[:hybridizations] array
    # with two Hybridization objects containing appropriate info
    @hybridizations = session[:hybridizations]
    assert_equal 2, @hybridizations.size
    assert_equal Date.new(2006, 2, 12), @hybridizations[0].date
    assert_equal 1, @hybridizations[0].chip_number
    assert_equal 1, @hybridizations[0].lab_group_id
    assert_equal 2, @hybridizations[0].chip_type_id
    assert_equal 2, @hybridizations[0].organism_id
    assert_equal 1, @hybridizations[0].charge_template_id
    assert_equal Date.new(2006, 2, 12), @hybridizations[1].date
    assert_equal 2, @hybridizations[1].chip_number
    assert_equal 1, @hybridizations[1].lab_group_id
    assert_equal 2, @hybridizations[1].chip_type_id   
    assert_equal 2, @hybridizations[1].organism_id
    assert_equal 1, @hybridizations[1].charge_template_id
    
    assert_response :success
    assert_template 'add'
    
    @hybridizations = session[:hybridizations]
    assert_equal 2, @hybridizations.size
  end

  def test_add_incomplete_form
    get :new
  
    get :add, :date => '2006-02-12', :lab_group_id => 1,
        :chip_type_id => 2
    
    # no hybridizations should have been added
    @hybridizations = session[:hybridizations]
    assert_equal @hybridizations.size, 0  
    
    # make sure it complained
    assert_errors
    assert_response :success
    assert_template 'add'
  end

  def test_create_all_tracking_on
    num_hybridizations = Hybridization.count
    num_transactions = ChipTransaction.count
    num_charges = Charge.count

    # use test_add to populate session[:hybridizations] and session[:hybridization_number]
    test_add_sbeams_on_in_site_config

    hyb1 = {:date => '2006-02-12',
            :chip_number => '1',
            :charge_template_id => '1',
            :short_sample_name => 'HlthySmpl',
            :sample_name => 'Healthy_Sample',
            :sample_group_name => 'Healthy',
            :lab_group_id => '2',
            :chip_type_id => '1',
            :organism_id => '1',
            :array_platform => 'affy'
            }
    hyb2 = {:date => '2006-02-12',
            :chip_number => '2',
            :charge_template_id => '1',
            :short_sample_name => 'DisSmpl',
            :sample_name => 'Disease_Sample',
            :sample_group_name => 'Disease',
            :lab_group_id => '2',
            :chip_type_id => '1',
            :organism_id => '1',
            :array_platform => 'affy'
            }  
                  
    post :create, :'hybridization-0' => hyb1, :'hybridization-1' => hyb2

    assert_response :redirect
    assert_redirected_to :action => 'show'

    # make sure the records made it into the hybridizations table
    assert_equal num_hybridizations + 2,
                 Hybridization.count
                 
    # make sure a chip transaction was recorded
    assert_equal num_transactions + 1,
                 ChipTransaction.count
                 
    # make sure a charge was recorded
    assert_equal num_charges + 2,
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
    test_add_sbeams_on_in_site_config

    hyb1 = {:date => '2006-02-12',
            :chip_number => '1',
            :charge_template_id => '1',
            :short_sample_name => 'HlthySmpl',
            :sample_name => 'Healthy_Sample',
            :sample_group_name => 'Healthy',
            :lab_group_id => '2',
            :chip_type_id => '1',
            :organism_id => '1',
            :array_platform => 'affy'
            }
    hyb2 = {:date => '2006-02-12',
            :chip_number => '2',
            :charge_template_id => '1',
            :short_sample_name => 'DisSmpl',
            :sample_name => 'Disease_Sample',
            :sample_group_name => 'Disease',
            :lab_group_id => '2',
            :chip_type_id => '1',
            :organism_id => '1',
            :array_platform => 'affy'
            }  
                  
    post :create, :'hybridization-0' => hyb1, :'hybridization-1' => hyb2

    assert_response :redirect
    assert_redirected_to :action => 'show'
    follow_redirect
    assert_flash_warning

    # make sure the records made it into the hybridizations table
    assert_equal num_hybridizations + 2,
                 Hybridization.count
                 
    # make sure a chip transaction was recorded
    assert_equal num_transactions + 1,
                 ChipTransaction.count
                 
    # make sure a charge was recorded
    assert_equal num_charges + 2,
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
    test_add_sbeams_on_in_site_config

    hyb1 = {:date => '2006-02-12',
            :chip_number => '1',
            :charge_template_id => '1',
            :short_sample_name => 'HlthySmpl',
            :sample_name => 'Healthy_Sample',
            :sample_group_name => 'Healthy',
            :lab_group_id => '2',
            :chip_type_id => '1',
            :organism_id => '1',
            :array_platform => 'affy'
            }
    hyb2 = {:date => '2006-02-12',
            :chip_number => '2',
            :charge_template_id => '1',
            :short_sample_name => 'DisSmpl',
            :sample_name => 'Disease_Sample',
            :sample_group_name => 'Disease',
            :lab_group_id => '2',
            :chip_type_id => '1',
            :organism_id => '1',
            :array_platform => 'affy'
            }  
                  
    post :create, :'hybridization-0' => hyb1, :'hybridization-1' => hyb2

    assert_response :redirect
    assert_redirected_to :action => 'show'

    # make sure the records made it into the hybridizations table
    assert_equal num_hybridizations + 2,
                 Hybridization.count
                 
    # make sure a chip transaction was recorded
    assert_equal num_transactions, ChipTransaction.count

    # make sure a charge was recorded
    assert_equal num_charges + 2,
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
    test_add_sbeams_on_in_site_config

    hyb1 = {:date => '2006-02-12',
            :chip_number => '1',
            :charge_template_id => '1',
            :short_sample_name => 'HlthySmpl',
            :sample_name => 'Healthy_Sample',
            :sample_group_name => 'Healthy',
            :lab_group_id => '2',
            :chip_type_id => '1',
            :organism_id => '1',
            :array_platform => 'affy'
            }
    hyb2 = {:date => '2006-02-12',
            :chip_number => '2',
            :charge_template_id => '1',
            :short_sample_name => 'DisSmpl',
            :sample_name => 'Disease_Sample',
            :sample_group_name => 'Disease',
            :lab_group_id => '2',
            :chip_type_id => '1',
            :organism_id => '1',
            :array_platform => 'affy'
            }  
                  
    post :create, :'hybridization-0' => hyb1, :'hybridization-1' => hyb2

    assert_response :redirect
    assert_redirected_to :action => 'show'

    # make sure the records made it into the hybridizations table
    assert_equal num_hybridizations + 2,
                 Hybridization.count
                 
    # make sure a chip transaction was recorded
    assert_equal num_transactions + 1,
                 ChipTransaction.count

    # make sure a charge was recorded
    assert_equal num_charges, Charge.count   
  end
  
  def test_create_incomplete_form
    num_hybridizations = Hybridization.count

    # use test_add to populate session[:hybridizations] and session[:hybridization_number]
    test_add_sbeams_on_in_site_config
    
    # leave out sample name
    hyb1 = {:date => '2006-02-12',
            :chip_number => '1',
            :short_sample_name => 'HlthySmpl',
            :lab_group_id => '2',
            :chip_type_id => '1'
            }
    hyb2 = {:date => '2006-02-12',
            :chip_number => '2',
            :sample_name => 'Disease_Sample',
            :short_sample_name => 'DisSmpl',
            :lab_group_id => '2',
            :chip_type_id => '1'
            }  
                       
    post :create, :'hybridization-0' => hyb1, :'hybridization-1' => hyb2

    # make sure it complained
    assert_errors
    assert_response :success
    assert_template 'add'

    # make sure records were not inserted
    assert_equal num_hybridizations, Hybridization.count
  end

  def test_create_duplicate_date_number_combo
    num_hybridizations = Hybridization.count

    # enter a new set of hybs
    get :new

    # add one hyb that will have a duplicate date/number  
    get :add, :add_hybs => {:date => '2006-02-10', :number => 1,
                            :lab_group_id => 1, :chip_type_id => 2,
                            :charge_template_id => 1 }
    # add another hyb with unique date/number
    get :add, :add_hybs => {:date => '2006-02-12', :number => 1,
                            :lab_group_id => 1, :chip_type_id => 2,
                            :charge_template_id => 1 }
    
    # leave out sample name
    hyb1 = {:short_sample_name => 'HlthySmpl',
            :sample_name => 'Healthy_Sample',
            :sample_group_name => 'Healthy',
            :organism_id => '2'
            }
    hyb2 = {:short_sample_name => 'DisSmpl',
            :sample_name => 'Disease_Sample',
            :sample_group_name => 'Disease',
            :organism_id => '2'
            }  
                       
    post :create, :'hybridization-0' => hyb1, :'hybridization-1' => hyb2

    # make sure it complained
    assert_errors
    assert_response :success
    assert_template 'add'

    # make sure records were not inserted
    assert_equal num_hybridizations, Hybridization.count
  end

  def test_clear
    # use test_add to populate session[:hybridizations] and session[:hybridization_number]
    test_add_sbeams_on_in_site_config
    
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
    post :update, :id => 1, :hybridization => { :date => '2006-02-09' }
    
    hybridization = Hybridization.find(1)
    assert_equal Date.new(2006,2,9), hybridization.date
    
    assert_response :redirect
    assert_redirected_to :action => 'list'
  end

  def test_update_locked
    # grab the hybridization we're going to use twice
    hybridization1 = Hybridization.find(1)
    hybridization2 = Hybridization.find(1)
    
    # update it once, which should sucess
    post :update, :id => 1, :hybridization => { :sample_name => "hybridization1", 
                                                :lock_version => hybridization1.lock_version }

    # and then update again with stale info, and it should fail
    post :update, :id => 1, :hybridization => { :sample_name => "hybridization2", 
                                                :lock_version => hybridization2.lock_version }                                               

    assert_response :success                                                
    assert_template 'edit'
    assert_flash_warning
    
    assert_equal "hybridization1", Hybridization.find(1).sample_name
  end

  def test_destroy
    assert_not_nil Hybridization.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Hybridization.find(1)
    }
  end
end

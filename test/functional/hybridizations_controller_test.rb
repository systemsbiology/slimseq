require File.dirname(__FILE__) + '/../test_helper'
require 'hybridizations_controller'
require 'assert_select'
require 'html_selector'
Test::Unit::TestCase.send :include, Test::Unit::AssertSelect

# Re-raise errors caught by the controller.
class HybridizationsController; def rescue_action(e) raise e end; end

class HybridizationsControllerTest < Test::Unit::TestCase
  fixtures :hybridizations, :samples, :projects,
           :lab_groups, :chip_types, :organisms, :charge_templates, :charge_sets,
           :quality_traces

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
  
    get :add, :selected_samples => { '1' => '1', '3' => '0',
                                     '5' => '0', '6' => '0' },
              :submit_hybridizations => {:hybridization_date => "2006-02-13", 
                            :charge_set_id => 1,
                            :charge_template_id => 1}

    assert_response :success
    assert_template 'add'
    
    # this should have populated the session[:hybridizations] array
    # with one Hybridization object containing appropriate info
    @hybridizations = session[:hybridizations]
    assert_equal 1, @hybridizations.size
    assert_equal Date.new(2006, 2, 13), @hybridizations[0].hybridization_date
    assert_equal 1, @hybridizations[0].chip_number
    assert_equal 1, @hybridizations[0].sample_id
    assert_equal 1, @hybridizations[0].charge_set_id
    assert_equal 1, @hybridizations[0].charge_template_id

    # make sure that only non-selected samples remain in selection list
    # should have 4 rows (header + 3 samples)
    assert_select "table#available_samples>tr", 4
  end

  def test_add_charge_set_based_on_sample
    # record initial number of charge sets
    num_charge_sets = ChargeSet.count

    # use test_new to populate session variables
    get :new
  
    get :add, :selected_samples => { '1' => '0', '3' => '0',
                                     '5' => '1', '6' => '0' },
              :submit_hybridizations => {:hybridization_date => "2006-09-29", 
                            :charge_set_id => -1,
                            :charge_template_id => 1}

    assert_response :success
    assert_template 'add'

    # make sure a charge set was successfully created
    assert_equal num_charge_sets + 1, ChargeSet.count
    new_charge_set = ChargeSet.find(:first, :order => "id DESC")
    assert_equal "Bob's Stuff", new_charge_set.name
    assert_equal "12345678", new_charge_set.budget
    assert_equal 2, new_charge_set.charge_period_id
    assert_equal 1, new_charge_set.lab_group_id
    
    # this should have populated the session[:hybridizations] array
    # with two Hybridization objects containing appropriate info
    @hybridizations = session[:hybridizations]
    assert_equal 1, @hybridizations.size
    assert_equal Date.new(2006, 9, 29), @hybridizations[0].hybridization_date
    assert_equal 1, @hybridizations[0].chip_number
    assert_equal 5, @hybridizations[0].sample_id
    assert_equal new_charge_set.id, @hybridizations[0].charge_set_id
    assert_equal 1, @hybridizations[0].charge_template_id

    # make sure that only only non-selected samples remain in selection list
    # should have 4 rows (header + 3 samples)
    assert_select "table#available_samples>tr", 4
  end

  def test_add_nothing_selected
    # use test_new to populate session variables
    get :new
  
    get :add, :selected_samples => { '1' => '0', '3' => '0',
                                     '5' => '0', '6' => '0' },
              :submit_hybridizations => {:hybridization_date => "2006-02-13", 
                            :charge_set_id => 1,
                            :charge_template_id => 1}

    assert_response :success
    assert_template 'add'
    
    # this should have populated the session[:hybridizations] array
    # with two Hybridization objects containing appropriate info
    @hybridizations = session[:hybridizations]
    assert_equal 0, @hybridizations.size

    # should have 5 rows (header + 4 samples)
    assert_select "table#available_samples>tr", 5
  end

  def test_multiple_adds
    # use test_new to populate session variables
    get :new
  
    get :add, :selected_samples => { '1' => '1', '3' => '0',
                                     '5' => '0', '6' => '0' },
              :submit_hybridizations => {:hybridization_date => "2006-02-13", 
                            :charge_set_id => 1,
                            :charge_template_id => 1}
    
    assert_response :success
    assert_template 'add'
    
    get :add, :selected_samples => { '3' => '1', '5' => '0', '6' => '0' },
              :submit_hybridizations => {:hybridization_date => "2006-02-13", 
                            :charge_set_id => 1,
                            :charge_template_id => 1}
                          
    assert_response :success
    assert_template 'add'
    
    # this should have populated the session[:hybridizations] array
    # with two Hybridization objects containing appropriate info
    @hybridizations = session[:hybridizations]
    assert_equal 2, @hybridizations.size
    assert_equal Date.new(2006, 2, 13), @hybridizations[0].hybridization_date
    assert_equal 1, @hybridizations[0].chip_number
    assert_equal 1, @hybridizations[0].sample_id
    assert_equal 1, @hybridizations[0].charge_set_id
    assert_equal 1, @hybridizations[0].charge_template_id
    assert_equal Date.new(2006, 2, 13), @hybridizations[1].hybridization_date
    assert_equal 2, @hybridizations[1].chip_number
    assert_equal 3, @hybridizations[1].sample_id
    assert_equal 1, @hybridizations[1].charge_set_id
    assert_equal 1, @hybridizations[1].charge_template_id

    # make sure that only non-selected samples remain in selection list
    # should have 3 rows (header + 2 samples)
    assert_select "table#available_samples>tr", 3
  end
  
  def test_create_all_tracking_on
    # copy images into place for use with this test
    FileUtils.cp("#{RAILS_ROOT}/test/fixtures/bioanalyzer_files/2100 expert_EukaryoteTotal RNA Nano_DE02000308_2004-07-29_11-23-22_EGRAM_Sample1.jpg",
                 "#{RAILS_ROOT}/public/quality_traces/2100expert_EukaryoteTotalRNANano_DE02000308_2004-07-29_11-23-22-Control_1-total.jpg")
    FileUtils.cp("#{RAILS_ROOT}/test/fixtures/bioanalyzer_files/2100 expert_EukaryoteTotal RNA Nano_DE02000308_2004-07-29_11-23-22_EGRAM_Sample5.jpg",
                 "#{RAILS_ROOT}/public/quality_traces/2100expert_EukaryoteTotalRNANano_DE02000308_2004-07-29_11-23-22-Control_1-cRNA.jpg")
    FileUtils.cp("#{RAILS_ROOT}/test/fixtures/bioanalyzer_files/2100 expert_EukaryoteTotal RNA Nano_DE02000308_2004-07-29_11-23-22_EGRAM_Sample9.jpg",
                 "#{RAILS_ROOT}/public/quality_traces/2100expert_EukaryoteTotalRNANano_DE02000308_2004-07-29_11-23-22-Control_1-fragmented.jpg")

    # set output directories to the rails root (we'll delete any test files when done)
    @site_config = SiteConfig.find(1)
    @site_config.update_attributes(:create_gcos_files => 1)
    @site_config.update_attributes(:using_sbeams => 1)
    @site_config.update_attributes(:gcos_output_path => "#{RAILS_ROOT}")
    @site_config.update_attributes(:quality_trace_dropoff => "#{RAILS_ROOT}")
    @site_config.update_attributes(:raw_data_root_path => "/raw/data/root")
    @site_config.save

    # get rid of any existing output folder
    if( File.exists?("#{RAILS_ROOT}/200602") )
      FileUtils.rm_rf("#{RAILS_ROOT}/200602")
    end
    # temporarily make a folder for output traces
    FileUtils.mkdir("#{RAILS_ROOT}/200602")

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

    # make sure raw data path was populated
    hybridization = Hybridization.find(:first, :order => "id DESC")
    assert_equal "/raw/data/root/200602/20060213_01_Young.CEL", hybridization.raw_data_path

    # make sure gcos file was created, then delete it
    assert File.exists?("#{RAILS_ROOT}/20060213_01_Young.txt")
    FileUtils.rm("#{RAILS_ROOT}/20060213_01_Young.txt")
    
    # make sure bioanalyzer trace files created, then delete them
    assert File.exists?("#{RAILS_ROOT}/200602/20060213_01_Young.EGRAM_T.jpg")
    assert File.exists?("#{RAILS_ROOT}/200602/20060213_01_Young.EGRAM_PF.jpg")
    assert File.exists?("#{RAILS_ROOT}/200602/20060213_01_Young.EGRAM_F.jpg")
    FileUtils.rm_rf("#{RAILS_ROOT}/200602")
    
    # remove files put into place during test
    FileUtils.rm("#{RAILS_ROOT}/public/quality_traces/2100expert_EukaryoteTotalRNANano_DE02000308_2004-07-29_11-23-22-Control_1-total.jpg")
    FileUtils.rm("#{RAILS_ROOT}/public/quality_traces/2100expert_EukaryoteTotalRNANano_DE02000308_2004-07-29_11-23-22-Control_1-cRNA.jpg")
    FileUtils.rm("#{RAILS_ROOT}/public/quality_traces/2100expert_EukaryoteTotalRNANano_DE02000308_2004-07-29_11-23-22-Control_1-fragmented.jpg")    
  end

  def test_create_bad_gcos_output_path
    # set a nonsensical gcos path
    @site_config = SiteConfig.find(1)
    @site_config.update_attributes(:create_gcos_files => true)
    @site_config.update_attributes(:gcos_output_path => '/path/that/should/not/work')
    @site_config.save

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

  def test_create_on_date_with_existing_hybridizations
    num_hybridizations = Hybridization.count
    num_transactions = ChipTransaction.count
    num_charges = Charge.count
    
    # enter a new set of hybs
    get :new

    get :add, :selected_samples => { '1' => '1', '2'=>'0', '3' => '0' },
              :submit_hybridizations => {:hybridization_date => "2006-02-10", 
                            :charge_set_id => 1,
                            :charge_template_id => 1}
                       
    post :create

    assert_response :redirect
    assert_redirected_to :action => 'show'

    assert_equal Hybridization.find(:first, :order => "id DESC").
      chip_number, 3
    
    # make sure the records made it into the hybridizations table
    assert_equal num_hybridizations + 1,
                 Hybridization.count
                 
    # make sure a chip transaction was recorded
    assert_equal num_transactions + 1,
                 ChipTransaction.count

    # make sure a charge was recorded
    assert_equal num_charges + 1, Charge.count   
  end

  def test_clear
    # use test_add to populate session[:hybridizations] and session[:hybridization_number]
    test_add
    
    post :clear
    
    assert_response :redirect
    assert_redirected_to :action => 'new'
    
    assert_equal 0, session[:hybridizations].size
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
  
    post :bulk_handler, :selected_hybridizations => {'1' => '1', '2' => '1'},
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

  def test_bulk_gcos_file_export_no_naming_scheme
    # set output directory to the rails root (we'll delete any test files when done)
    @site_config = SiteConfig.find(1)
    @site_config.update_attributes(:create_gcos_files => 1)
    @site_config.update_attributes(:using_sbeams => 1)
    @site_config.update_attributes(:gcos_output_path => "#{RAILS_ROOT}")
    @site_config.save
  
    post :bulk_handler, :selected_hybridizations => {'1' => '1', '2' => '0'},
         :commit => "Export GCOS Files"
    
    assert_response :redirect
    assert_redirected_to :action => 'list'

    # make sure gcos files was created, then delete it
    assert File.exists?("#{RAILS_ROOT}/20060210_01_Old.txt")
    FileUtils.rm("#{RAILS_ROOT}/20060210_01_Old.txt")
  end

  def test_bulk_gcos_file_export_with_naming_scheme
    # select a naming scheme for current user
    current_user = User.find(@request.session[:user_id])
    current_user.current_naming_scheme_id = 1
    current_user.save
    
    # set output directory to the rails root (we'll delete any test files when done)
    @site_config = SiteConfig.find(1)
    @site_config.update_attributes(:create_gcos_files => 1)
    @site_config.update_attributes(:using_sbeams => 1)
    @site_config.update_attributes(:gcos_output_path => "#{RAILS_ROOT}")
    @site_config.save
  
    post :bulk_handler, :selected_hybridizations => {'1' => '1', '2' => '0'},
         :commit => "Export GCOS Files"
    
    assert_response :redirect
    assert_redirected_to :action => 'list'

    # make sure gcos files was created, then delete it
    assert File.exists?("#{RAILS_ROOT}/20060210_01_Old.txt")
    FileUtils.rm("#{RAILS_ROOT}/20060210_01_Old.txt")
    
    # go back to no naming scheme
    current_user.current_naming_scheme_id = nil
    current_user.save
  end

  
  def test_bulk_bioanalyzer_trace_export
    # copy images into place for use with this test
    FileUtils.cp("#{RAILS_ROOT}/test/fixtures/bioanalyzer_files/2100 expert_EukaryoteTotal RNA Nano_DE02000308_2004-07-29_11-23-22_EGRAM_Sample2.jpg",
                 "#{RAILS_ROOT}/public/quality_traces/2100expert_EukaryoteTotalRNANano_DE02000308_2004-07-29_11-23-22-Control_2-total.jpg")
    FileUtils.cp("#{RAILS_ROOT}/test/fixtures/bioanalyzer_files/2100 expert_EukaryoteTotal RNA Nano_DE02000308_2004-07-29_11-23-22_EGRAM_Sample6.jpg",
                 "#{RAILS_ROOT}/public/quality_traces/2100expert_EukaryoteTotalRNANano_DE02000308_2004-07-29_11-23-22-Control_2-cRNA.jpg")
    FileUtils.cp("#{RAILS_ROOT}/test/fixtures/bioanalyzer_files/2100 expert_EukaryoteTotal RNA Nano_DE02000308_2004-07-29_11-23-22_EGRAM_Sample10.jpg",
                 "#{RAILS_ROOT}/public/quality_traces/2100expert_EukaryoteTotalRNANano_DE02000308_2004-07-29_11-23-22-Control_2-fragmented.jpg")

    # set output directories to the rails root (we'll delete any test files when done)
    @site_config = SiteConfig.find(1)
    @site_config.update_attributes(:using_sbeams => 1)
    @site_config.update_attributes(:quality_trace_dropoff => "#{RAILS_ROOT}")
    @site_config.save    

    # get rid of any existing output folder
    if( File.exists?("#{RAILS_ROOT}/200602") )
      FileUtils.rm_rf("#{RAILS_ROOT}/200602")
    end
    # temporarily make a folder for output traces
    FileUtils.mkdir("#{RAILS_ROOT}/200602")
    
    post :bulk_handler, :selected_hybridizations => {'1' => '1', '2' => '0'},
         :commit => "Export Bioanalyzer Images"
    
    assert_response :redirect
    assert_redirected_to :action => 'list'
    
    # make sure bioanalyzer trace files created, then delete them
    assert File.exists?("#{RAILS_ROOT}/200602/20060210_01_Old.EGRAM_T.jpg")
    assert File.exists?("#{RAILS_ROOT}/200602/20060210_01_Old.EGRAM_PF.jpg")
    assert File.exists?("#{RAILS_ROOT}/200602/20060210_01_Old.EGRAM_F.jpg")
    FileUtils.rm_rf("#{RAILS_ROOT}/200602")
    
    # remove files put into place during test
    FileUtils.rm("#{RAILS_ROOT}/public/quality_traces/2100expert_EukaryoteTotalRNANano_DE02000308_2004-07-29_11-23-22-Control_2-total.jpg")
    FileUtils.rm("#{RAILS_ROOT}/public/quality_traces/2100expert_EukaryoteTotalRNANano_DE02000308_2004-07-29_11-23-22-Control_2-cRNA.jpg")
    FileUtils.rm("#{RAILS_ROOT}/public/quality_traces/2100expert_EukaryoteTotalRNANano_DE02000308_2004-07-29_11-23-22-Control_2-fragmented.jpg")    
  end
end

require File.dirname(__FILE__) + '/../test_helper'
require 'samples_controller'

# Re-raise errors caught by the controller.
class SamplesController; def rescue_action(e) raise e end; end

class SamplesControllerTest < Test::Unit::TestCase
  fixtures :samples, 
           :lab_groups, :chip_types, :organisms

  def setup
    @controller = SamplesController.new
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

    assert_not_nil assigns(:samples)
  end

  def test_new_gcos_on_sbeams_on_in_site_config
    get :new

    assert_response :success
    assert_template 'new'
    
    assert_text_field_visible "add_samples_sbeams_user"
    assert_text_field_visible "add_samples_sbeams_project"
  end

  def test_new_affy_platform_gcos_on_sbeams_off_in_site_config
    # turn off GCOS support
    config = SiteConfig.find(1)
    config.update_attributes(:create_gcos_files => 1,
                             :using_sbeams => 0)
  
    get :new

    assert_response :success
    assert_template 'new'
    
    assert_text_field_visible "add_samples_sbeams_user"
    assert_text_field_visible "add_samples_sbeams_project"
  end

  def test_new_non_affy_platform_gcos_off_in_site_config
    # turn off GCOS support and turn to non-affy mode
    config = SiteConfig.find(1)
    config.update_attributes(:create_gcos_files => 0,
                             :array_platform => "nonaffy")
  
    get :new

    assert_response :success
    assert_template 'new'
    
    assert_text_field_hidden "add_samples_sbeams_user"
    assert_text_field_hidden "add_samples_sbeams_project"
  end

  def test_add_sbeams_on_in_site_config
    # use test_new to populate session variables
    get :new
  
    get :add, :add_samples => {:date => "2006-02-12", :number => 2,
                            :lab_group_id => 1, :chip_type_id => 2,
                            :sbeams_user => "Bob", :sbeams_project => "Bob's Stuff"}
    
    # this should have populated the session[:samples] array
    # with two Sample objects containing appropriate info
    @samples = session[:samples]
    assert_equal 2, @samples.size
    assert_equal Date.new(2006, 2, 12), @samples[0].date
    assert_equal 1, @samples[0].lab_group_id
    assert_equal 2, @samples[0].chip_type_id
    assert_equal 2, @samples[0].organism_id
    assert_equal "Bob", @samples[0].sbeams_user
    assert_equal "Bob's Stuff", @samples[0].sbeams_project
    assert_equal Date.new(2006, 2, 12), @samples[1].date
    assert_equal 1, @samples[1].lab_group_id
    assert_equal 2, @samples[1].chip_type_id   
    assert_equal 2, @samples[1].organism_id
    assert_equal "Bob", @samples[1].sbeams_user
    assert_equal "Bob's Stuff", @samples[1].sbeams_project
    
    assert_response :success
    assert_template 'add'
    
    @samples = session[:samples]
    assert_equal 2, @samples.size
  end

  def test_add_gcos_off_in_site_config
    # turn off GCOS support
    config = SiteConfig.find(1)
    config.update_attributes(:create_gcos_files => 0)

    # use test_new to populate session variables
    get :new
  
    get :add, :add_samples => {:date => "2006-02-12", :number => 2,
                            :lab_group_id => 1, :chip_type_id => 2}
    
    # this should have populated the session[:samples] array
    # with two Sample objects containing appropriate info
    @samples = session[:samples]
    assert_equal 2, @samples.size
    assert_equal Date.new(2006, 2, 12), @samples[0].date
    assert_equal 1, @samples[0].lab_group_id
    assert_equal 2, @samples[0].chip_type_id
    assert_equal 2, @samples[0].organism_id
    assert_equal Date.new(2006, 2, 12), @samples[1].date
    assert_equal 1, @samples[1].lab_group_id
    assert_equal 2, @samples[1].chip_type_id   
    assert_equal 2, @samples[1].organism_id
    
    assert_response :success
    assert_template 'add'
    
    @samples = session[:samples]
    assert_equal 2, @samples.size
  end

  def test_add_incomplete_form
    get :new
  
    get :add, :date => '2006-02-12', :lab_group_id => 1,
        :chip_type_id => 2
    
    # no samples should have been added
    @samples = session[:samples]
    assert_equal @samples.size, 0  
    
    # make sure it complained
    assert_errors
    assert_response :success
    assert_template 'add'
  end

  def test_create_all_tracking_on
    num_samples = Sample.count
    num_transactions = ChipTransaction.count
    num_charges = Charge.count

    # use test_add to populate session[:samples] and session[:sample_number]
    test_add_sbeams_on_in_site_config

    smpl1 = {:date => '2006-02-12',
            :short_sample_name => 'HlthySmp',
            :sample_name => 'Healthy_Sample',
            :sample_group_name => 'Healthy',
#            :lab_group_id => '2',
#            :chip_type_id => '1',
            :organism_id => '1',
            }
    smpl2 = {:date => '2006-02-12',
            :short_sample_name => 'DisSmpl',
            :sample_name => 'Disease_Sample',
            :sample_group_name => 'Disease',
#            :lab_group_id => '2',
#            :chip_type_id => '1',
            :organism_id => '1',
            }  

    post :create, :'sample-0' => smpl1, :'sample-1' => smpl2

    assert_response :redirect
    assert_redirected_to :action => 'show'

    # make sure the records made it into the samples table
    assert_equal num_samples + 2,
                 Sample.count
                 
  end

  def test_create_duplicate_sample_name
    num_samples = Sample.count

    # enter a new set of samples
    get :new

    # add one sample that will have a duplicate date/number  
    get :add, :add_samples => {:date => '2006-02-10', :number => 1,
                            :lab_group_id => 1, :chip_type_id => 2}
    # add another sample with unique date/number
    get :add, :add_samples => {:date => '2006-02-12', :number => 1,
                            :lab_group_id => 1, :chip_type_id => 2}
    
    # leave out sample name
    smpl1 = {:short_sample_name => 'HlthySmpl',
            :sample_name => 'Healthy_Sample',
            :sample_group_name => 'Healthy',
            :organism_id => '2'
            }
    smpl2 = {:short_sample_name => 'Hty',
            :sample_name => 'Healthy_Sample',
            :sample_group_name => 'Health',
            :organism_id => '2'
            }  
                       
    post :create, :'sample-0' => smpl1, :'sample-1' => smpl2

    # make sure it complained
    assert_errors
    assert_response :success
    assert_template 'add'

    # make sure records were not inserted
    assert_equal num_samples, Sample.count
  end

  def test_clear
    # use test_add to populate session[:samples] and session[:sample_number]
    test_add_sbeams_on_in_site_config
    
    post :clear
    
    assert_response :redirect
    assert_redirected_to :action => 'new'
    
    assert_equal 0, session[:samples].size
    assert_equal 0, session[:sample_number]
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

    assert_not_nil assigns(:sample)
    assert assigns(:sample).valid?
  end

  def test_update
    post :update, :id => 1, :sample => { :date => '2006-02-09' }
    
    sample = Sample.find(1)
    assert_equal Date.new(2006,2,9), sample.date
    
    assert_response :redirect
    assert_redirected_to :action => 'list'
  end

  def test_update_locked
    # grab the sample we're going to use twice
    sample1 = Sample.find(1)
    sample2 = Sample.find(1)
    
    # update it once, which should sucess
    post :update, :id => 1, :sample => { :sample_name => "sample1", 
                                                :lock_version => sample1.lock_version }

    # and then update again with stale info, and it should fail
    post :update, :id => 1, :sample => { :sample_name => "sample2", 
                                                :lock_version => sample2.lock_version }                                               

    assert_response :success                                                
    assert_template 'edit'
    assert_flash_warning
    
    assert_equal "sample1", Sample.find(1).sample_name
  end

  def test_destroy
    assert_not_nil Sample.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Sample.find(1)
    }
  end
end

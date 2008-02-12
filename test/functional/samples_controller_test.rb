require File.dirname(__FILE__) + '/../test_helper'
require 'samples_controller'

# Re-raise errors caught by the controller.
class SamplesController; def rescue_action(e) raise e end; end

class SamplesControllerTest < Test::Unit::TestCase
  fixtures :samples, :projects, :bioanalyzer_runs, :quality_traces,
           :lab_groups, :chip_types, :organisms, :lab_memberships,
           :users, :roles, :permissions, :users_roles, :permissions_roles,
           :naming_schemes , :naming_elements, :naming_terms,
           :sample_terms

  def setup
    @controller = SamplesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

#################################
#
# Run all tests as admin user
#
#################################

  def test_index_as_admin
    login_as_admin
  
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list_as_admin
    login_as_admin
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:samples)
  end

  def test_new_gcos_on_sbeams_on_in_site_config_as_admin
    login_as_admin

    # turn on gcos and sbeams options
    @site_config = SiteConfig.find(1)
    @site_config.update_attributes(:create_gcos_files => 1)
    @site_config.update_attributes(:using_sbeams => 1)
    @site_config.save

    get :new

    assert_response :success
    assert_template 'new'
    
    assert_text_field_visible "add_samples_sbeams_user"
  end

  def test_new_affy_platform_gcos_on_sbeams_off_in_site_config_as_admin
    login_as_admin
    # turn off GCOS support
    config = SiteConfig.find(1)
    config.update_attributes(:create_gcos_files => 1,
                             :using_sbeams => 0)
  
    get :new

    assert_response :success
    assert_template 'new'
    
    assert_text_field_visible "add_samples_sbeams_user"
  end

  def test_new_non_affy_platform_gcos_off_in_site_config_as_admin
    login_as_admin
    # turn off GCOS support and turn to non-affy mode
    config = SiteConfig.find(1)
    config.update_attributes(:create_gcos_files => 0,
                             :array_platform => "nonaffy")
  
    get :new

    assert_response :success
    assert_template 'new'
    
    assert_text_field_hidden "add_samples_sbeams_user"
  end

  def test_add_sbeams_on_in_site_config_project_from_dropdown_as_admin
    login_as_admin
    # use new to populate session variables
    get :new
  
    get :add, :add_samples => {:submission_date => "2006-02-12", :number => 2,
                            :project_id => 1, :chip_type_id => 2,
                            :sbeams_user => "Bob"}
    
    # this should have populated the session[:samples] array
    # with two Sample objects containing appropriate info
    @samples = session[:samples]
    assert_equal 2, @samples.size
    assert_equal Date.new(2006, 2, 12), @samples[0].submission_date
    assert_equal 1, @samples[0].project_id
    assert_equal 2, @samples[0].chip_type_id
    assert_equal 2, @samples[0].organism_id
    assert_equal "Bob", @samples[0].sbeams_user
    assert_equal Date.new(2006, 2, 12), @samples[1].submission_date
    assert_equal 1, @samples[1].project_id
    assert_equal 2, @samples[1].chip_type_id   
    assert_equal 2, @samples[1].organism_id
    assert_equal "Bob", @samples[1].sbeams_user
    
    assert_response :success
    assert_template 'add'
    
    @samples = session[:samples]
    assert_equal 2, @samples.size
  end

  def test_add_gcos_off_in_site_config_project_from_dropdown_as_admin
    login_as_admin
    # turn off GCOS support
    config = SiteConfig.find(1)
    config.update_attributes(:create_gcos_files => 0)

    # use test_new to populate session variables
    get :new
  
    get :add, :add_samples => {:submission_date => "2006-02-12", :number => 2,
                            :project_id => 1, :chip_type_id => 2}
    
    # this should have populated the session[:samples] array
    # with two Sample objects containing appropriate info
    @samples = session[:samples]
    assert_equal 2, @samples.size
    assert_equal Date.new(2006, 2, 12), @samples[0].submission_date
    assert_equal 1, @samples[0].project_id
    assert_equal 2, @samples[0].chip_type_id
    assert_equal 2, @samples[0].organism_id
    assert_equal Date.new(2006, 2, 12), @samples[1].submission_date
    assert_equal 1, @samples[1].project_id
    assert_equal 2, @samples[1].chip_type_id   
    assert_equal 2, @samples[1].organism_id
    
    assert_response :success
    assert_template 'add'
    
    @samples = session[:samples]
    assert_equal 2, @samples.size
  end

  def test_add_incomplete_form_project_from_dropdown
    login_as_admin
    get :new
  
    get :add, :submission_date => '2006-02-12', :project_id => 1,
        :chip_type_id => 2
    
    # no samples should have been added
    @samples = session[:samples]
    assert_equal @samples.size, 0  
    
    # make sure it complained
    assert_errors
    assert_response :success
    assert_template 'add'
  end

  def test_add_project_from_form_as_admin
    login_as_admin
    num_projects = Project.count

    # use new to populate session variables
    get :new
  
    get :add, :add_samples => {:submission_date => "2006-02-12", :number => 2,
                               :project_id => -1, :chip_type_id => 2,
                               :sbeams_user => "Bob"},
              :project => {:name => "Test Project",
                           :budget => "12340001", :lab_group_id => 2}
    
    # this should have populated the session[:samples] array
    # with two Sample objects containing appropriate info
    @samples = session[:samples]
    assert_equal 2, @samples.size
    assert_equal Date.new(2006, 2, 12), @samples[0].submission_date
    assert_equal 2, @samples[0].chip_type_id
    assert_equal 2, @samples[0].organism_id
    assert_equal "Bob", @samples[0].sbeams_user
    assert_equal Date.new(2006, 2, 12), @samples[1].submission_date
    assert_equal 2, @samples[1].chip_type_id   
    assert_equal 2, @samples[1].organism_id
    assert_equal "Bob", @samples[1].sbeams_user

    # there should also be a new project with the info
    # provided
    assert_equal num_projects + 1, Project.count
    # here's the way to grab the most recently created Project
    new_project = Project.find(:first, :order => "id DESC")
    assert_equal "Test Project", new_project.name
    assert_equal "12340001", new_project.budget
    assert_equal 2, new_project.lab_group_id

    assert_response :success
    assert_template 'add'
    
    @samples = session[:samples]
    assert_equal 2, @samples.size
  end

  def test_add_naming_scheme_selected_as_admin
    login_as_admin

    # select a naming scheme for current user
    current_user = User.find(@request.session[:user].id)
    current_user.current_naming_scheme_id = 1
    current_user.save

    # use new to populate session variables
    get :new
  
    get :add, :add_samples => {:submission_date => "2006-02-12", :number => 2,
                            :project_id => 1, :chip_type_id => 2,
                            :sbeams_user => "Bob"}
    # this should have populated the session[:samples] array
    # with two Sample objects containing appropriate info
    @samples = session[:samples]
    assert_equal 2, @samples.size
    assert_equal Date.new(2006, 2, 12), @samples[0].submission_date
    assert_equal 1, @samples[0].project_id
    assert_equal 2, @samples[0].chip_type_id
    assert_equal 2, @samples[0].organism_id
    assert_equal "Bob", @samples[0].sbeams_user
    assert_equal Date.new(2006, 2, 12), @samples[1].submission_date
    assert_equal 1, @samples[1].project_id
    assert_equal 2, @samples[1].chip_type_id   
    assert_equal 2, @samples[1].organism_id
    assert_equal "Bob", @samples[1].sbeams_user
    
    assert_response :success
    assert_template 'add'
    
    @samples = session[:samples]
    assert_equal 2, @samples.size

    # go back to no naming scheme
    current_user.current_naming_scheme_id = nil
    current_user.save
  end

  def test_create_all_tracking_on_as_admin
    login_as_admin
    num_samples = Sample.count
    num_transactions = ChipTransaction.count
    num_charges = Charge.count

    # use test_add to populate session[:samples] and session[:sample_number]
    test_add_sbeams_on_in_site_config_project_from_dropdown_as_admin

    smpl1 = {:submission_date => '2006-02-12',
            :short_sample_name => 'HlthySmp',
            :sample_name => 'Healthy_Sample',
            :sample_group_name => 'Healthy',
            :organism_id => '1',
            }
    smpl2 = {:submission_date => '2006-02-12',
            :short_sample_name => 'DisSmpl',
            :sample_name => 'Disease_Sample',
            :sample_group_name => 'Disease',
            :organism_id => '1',
            }  

    post :create, :'sample-0' => smpl1, :'sample-1' => smpl2

    assert_response :redirect
    assert_redirected_to :action => 'show'

    # make sure the records made it into the samples table
    assert_equal num_samples + 2,
                 Sample.count
                 
  end

  def test_create_naming_scheme_selected_as_admin
    login_as_admin
    num_samples = Sample.count
    num_transactions = ChipTransaction.count
    num_charges = Charge.count

    # use test_add to populate session[:samples] and session[:sample_number]
    test_add_naming_scheme_selected_as_admin

    smpl1 = {:submission_date => '2006-02-12',
            :short_sample_name => 'HlthySmp',
            :organism_id => '1',
            }
    smpl1_schemed = {:'Strain' => 1,
                    :'Perturbation' => 1,
                    :'Perturbation Time' => 2,
                    :'Subject Number' => '42231'
                    }
    smpl2 = {:submission_date => '2006-02-12',
            :short_sample_name => 'DisSmpl',
            :organism_id => '1',
            }  
    smpl2_schemed = {:'Strain' => 2,
                    :'Perturbation' => -1,
                    :'Subject Number' => '42643'
                    }

    # select a naming scheme for current user
    current_user = User.find(@request.session[:user].id)
    current_user.current_naming_scheme_id = 1
    current_user.save
    
    # have to set session user before post, even though this isn't
    # necessary before get request
    session[:user] = current_user

    post :create, :'sample-0' => smpl1, :'sample-0_schemed_name' => smpl1_schemed,
                  :'sample-1' => smpl2, :'sample-1_schemed_name' => smpl2_schemed

    # select a naming scheme for current user
    current_user.current_naming_scheme_id = nil
    current_user.save

    assert_response :redirect
    assert_redirected_to :action => 'show'

    # make sure the records made it into the samples table
    assert_equal num_samples + 2,
                 Sample.count
                 
  end

  def test_create_duplicate_sample_name_as_admin
    login_as_admin
    num_samples = Sample.count

    # enter a new set of samples
    get :new

    # add one sample that will have a duplicate submission_date/number  
    get :add, :add_samples => {:submission_date => '2006-02-10', :number => 1,
                            :project_id => 1, :chip_type_id => 2}
    # add another sample with unique submission_date/number
    get :add, :add_samples => {:submission_date => '2006-02-12', :number => 1,
                            :project_id => 1, :chip_type_id => 2}
    
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

  def test_clear_as_admin
    login_as_admin
    # use test_add to populate session[:samples] and session[:sample_number]
    test_add_sbeams_on_in_site_config_project_from_dropdown_as_admin
    
    post :clear
    
    assert_response :redirect
    assert_redirected_to :action => 'new'
    
    assert_equal 0, session[:samples].size
    assert_equal 0, session[:sample_number]
  end

  def test_show_as_admin
    login_as_admin
    get :show  

    assert_response :success
    assert_template 'show'
  end

  def test_edit_without_naming_scheme_as_admin
    login_as_admin
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:sample)
    assert assigns(:sample).valid?
  end

  def test_edit_with_naming_scheme_as_admin
    login_as_admin

    # select a naming scheme for current user
    current_user = User.find(@request.session[:user].id)
    current_user.current_naming_scheme_id = 1
    current_user.save
    
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:sample)
    assert assigns(:sample).valid?
  end

  def test_update_without_naming_scheme_as_admin
    login_as_admin
    post :update, :id => 1, :sample => { :submission_date => '2006-02-09',
                                         :sample_group_name => 'new group' }
    
    sample = Sample.find(1)
    assert_equal Date.new(2006,2,9), sample.submission_date
    assert_equal "new group", sample.sample_group_name
    
    assert_response :redirect
    assert_redirected_to :action => 'list'
  end

  def test_update_with_naming_scheme_as_admin
    login_as_admin

    # select a naming scheme for current user
    current_user = User.find(@request.session[:user].id)
    current_user.current_naming_scheme_id = 1
    current_user.save
    
    post :update, :id => 6, :sample => { :submission_date => '2006-02-09' },
                            :'sample-0_schemed_name' => { :Strain => 1,
                                                          :Perturbation => 3,
                                                          :'Perturbation Time' => 6,
                                                          :Replicate => 7,
                                                          :'Subject Number' => 32235
                                                         } 
    
    sample = Sample.find(6)
    assert_equal Date.new(2006,2,9), sample.submission_date
    assert_equal "wt_HT_024_A_32235", sample.sample_name
    assert_equal "wt_HT_024", sample.sample_group_name
    
    sample_terms = SampleTerm.find(:all, :conditions => ["sample_id = ?", 6],
                                   :order => "term_order ASC")
    assert_equal 4, sample_terms.size
    expected_terms = [1,3,6,7]
    for i in 0..expected_terms.size-1
      assert_equal expected_terms[i], sample_terms[i].naming_term_id
    end
    
    assert_response :redirect
    assert_redirected_to :action => 'list'
  end

  def test_update_locked_without_naming_scheme_as_admin
    login_as_admin
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

  def test_destroy_submitted_sample_as_admin
    login_as_admin
    assert_not_nil Sample.find(1)

    @request.env["HTTP_REFERER"] = "/samples/list"
    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to "samples/list"

    assert_raise(ActiveRecord::RecordNotFound) {
      Sample.find(1)
    }
  end

  def test_destroy_hybridized_sample_as_admin
    login_as_admin
    assert_not_nil Sample.find(2)

    @request.env["HTTP_REFERER"] = "/samples/list"
    post :destroy, :id => 2
    assert_response :redirect
    assert_redirected_to "samples/list"

    assert_raise(ActiveRecord::RecordNotFound) {
      Sample.find(2)
    }
  end

  def test_bulk_destroy
    login_as_admin
    post :bulk_destroy, :selected_samples => {'1' => '1', '2' => '1'},
         :commit => "Delete Samples"
    
    assert_response :redirect
    assert_redirected_to :action => 'list'

    # assert that destroys have taken place
    assert_raise(ActiveRecord::RecordNotFound) {
      Sample.find(1)
    }
    assert_raise(ActiveRecord::RecordNotFound) {
      Sample.find(2)
    }
  end

  # choose a couple of total RNA traces and request labeling
  def test_submit_traces_request_labeling_total_RNA_only_as_admin
    login_as_admin
    
    post :submit_traces, :commit => 'Request Labeling',
                         :selected_traces => {'1' => '1', '2' => '1'}
                         
    assert_no_flash_warning
    assert_response :success
    assert_template 'new_from_traces'
  end

  # choose a couple of total RNA and cRNA traces
  def test_submit_traces_request_labeling_total_RNA_and_others_as_admin
    login_as_admin
    
    post :submit_traces, :commit => 'Request Labeling',
                         :selected_traces => {'1' => '1', '2' => '1', '10' => '1'}

    assert_flash_warning
    assert_response :success
    assert_template 'new_from_traces'
  end

  # choose a couple of total RNA traces and request labeling, then
  # create samples
  def test_create_from_traces_from_labeling_request_as_admin
    login_as_admin
    num_samples = Sample.count
    
    # use submit_traces to populate session[:samples]
    test_submit_traces_request_labeling_total_RNA_only_as_admin
              
    post :create_from_traces, :add_samples => {:submission_date => '2006-11-29',
                                               :chip_type_id => 1,
                                               :sbeams_user => 'janderson',
                                               :project_id => 1},
                              :'sample-0' => {:short_sample_name => 'wA',
                                              :sample_name => 'WT_A',
                                              :sample_group_name => 'WT'},
                              :'sample-1' => {:short_sample_name => 'mA',
                                              :sample_name => 'Mut_A',
                                              :sample_group_name => 'Mut'}
    
    assert_response :redirect
    assert_redirected_to :action => 'show'

    # make sure the records made it into the samples table
    assert_equal num_samples + 2,
                 Sample.count
  end
  
  # choose a couple of total RNA traces and request labeling, then
  # create samples, then select cRNA and fragmented traces and request
  # hybridization
  def test_submit_traces_from_labeling_request_as_admin
    login_as_admin

    post :submit_traces, :commit => 'Request Labeling',
                         :selected_traces => {'6' => '1', '7' => '1'}
    
    post :create_from_traces, :add_samples => {:submission_date => '2006-11-28',
                                               :chip_type_id => 1,
                                               :sbeams_user => 'janderson',
                                               :project_id => 1},
                              :'sample-0' => {:short_sample_name => 'c1',
                                              :sample_name => 'Control_1',
                                              :sample_group_name => 'con'},
                              :'sample-1' => {:short_sample_name => 'c2',
                                              :sample_name => 'Control_2',
                                              :sample_group_name => 'con'}
        
    post :submit_traces, :commit => 'Request Hybridization',
                         :selected_traces => {'10' => '1', '14' => '1',
                                              '11' => '1', '15' => '1'}

    assert_response :success
    assert_template 'match_traces'
  end

  # choose a couple of total RNA traces and request labeling, then
  # create samples, select cRNA and fragmented traces and request
  # hybridization and finally submit the matched traces/samples
  def test_submit_matched_traces_from_labeling_request_as_admin
    login_as_admin
      
    test_submit_traces_from_labeling_request_as_admin

    num_samples = Sample.count
    
    # find samples that were created
    s1 = Sample.find(:first, :conditions => ["starting_quality_trace_id = 6"])
    s2 = Sample.find(:first, :conditions => ["starting_quality_trace_id = 7"])
    
    post :submit_matched_traces, :num_samples => '2',
                                 :'sample-0' => {:starting_quality_trace_id => '6',
                                                 :amplified_quality_trace_id => '10',
                                                 :fragmented_quality_trace_id => '14',
                                                 :id => s1.id},
                                 :'sample-1' => {:starting_quality_trace_id => '7',
                                                 :amplified_quality_trace_id => '11',
                                                 :fragmented_quality_trace_id => '15',
                                                 :id => s2.id}

    assert_response :redirect
    assert_redirected_to :action => 'show'
    
    # no new samples should have been created during submit_matched_traces
    assert_equal num_samples, Sample.count
    
    # verify that the samples are now tagged with the correct trace ids
    s1 = Sample.find(:first, :conditions => ["starting_quality_trace_id = 6"])
    s2 = Sample.find(:first, :conditions => ["starting_quality_trace_id = 7"])
    assert_equal 10, s1.amplified_quality_trace_id
    assert_equal 14, s1.fragmented_quality_trace_id
    assert_equal 11, s2.amplified_quality_trace_id
    assert_equal 15, s2.fragmented_quality_trace_id
  end

  # choose a set of traces (total RNA/cRNA/fragmented),
  # all with the same name, and request hybridization
  def test_submit_traces_request_hybridization_as_admin
    login_as_admin
    
    post :submit_traces, :commit => 'Request Hybridization',
                         :selected_traces => {'6' => '1', '10' => '1', '14' => '1'}

    assert_response :success
    assert_template 'match_traces'
    
    # should have fields for one sample
    assert_tag :tag => 'select', :attributes => { :id => 'sample-0_starting_quality_trace_id' }

    # but not two samples
    assert_no_tag :tag => 'select', :attributes => { :id => 'sample-1_starting_quality_trace_id' }
  end

  # choose a set of traces (total RNA/cRNA/fragmented),
  # all with the same name, request hybridization and then
  # submit matched up traces
  def test_submit_matched_traces_from_hybridization_request_as_admin
    login_as_admin
    
    test_submit_traces_request_hybridization_as_admin
    
    post :submit_matched_traces, :num_samples => '1',
                                 :'sample-0' => {:starting_quality_trace_id => '6',
                                                 :amplified_quality_trace_id => '10',
                                                 :fragmented_quality_trace_id => '14',
                                                 :id => '0'}
    
    assert_response :success
    assert_template 'new_from_traces'
  end

  # choose a set of traces (total RNA/cRNA/fragmented),
  # all with the same name, request hybridization,
  # submit matched up traces and then create samples
  def test_create_from_traces_from_hybridization_request_as_admin
    login_as_admin
    
    num_samples = Sample.count
    
    # use submit_traces to populate session[:samples]
    test_submit_matched_traces_from_hybridization_request_as_admin
              
    post :create_from_traces, :add_samples => {:submission_date => '2006-11-29',
                                               :chip_type_id => 1,
                                               :sbeams_user => 'janderson',
                                               :project_id => 1},
                              :'sample-0' => {:short_sample_name => 'c1',
                                              :sample_name => 'Control_1',
                                              :sample_group_name => 'con'}
    
    assert_response :redirect
    assert_redirected_to :action => 'show'

    # make sure the records made it into the samples table
    assert_equal num_samples + 1,
                 Sample.count
  end

  # choose a set of traces (total RNA/cRNA/fragmented),
  # all with the same name, and choose to match to
  # hybridized samples
  def test_submit_traces_match_to_hybridized_samples_as_admin
    login_as_admin
    
    post :submit_traces, :commit => 'Match to Hybridized Samples',
                         :selected_traces => {'6' => '1', '10' => '1', '14' => '1'}

    assert_response :success
    assert_template 'match_traces'
    
    # should have fields for one sample
    assert_tag :tag => 'select', :attributes => { :id => 'sample-0_starting_quality_trace_id' }

    # but not two samples
    assert_no_tag :tag => 'select', :attributes => { :id => 'sample-1_starting_quality_trace_id' }
  end

###########################################
#
# Test all functionality available to customer
#
###########################################

  def test_index_as_customer
    login_as_customer
  
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list_as_customer
    login_as_customer

    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:samples)
  end

  def test_new_gcos_on_sbeams_on_in_site_config_as_customer
    login_as_customer

    # turn on gcos and sbeams options
    @site_config = SiteConfig.find(1)
    @site_config.update_attributes(:create_gcos_files => 1)
    @site_config.update_attributes(:using_sbeams => 1)
    @site_config.save
    
    get :new

    assert_response :success
    assert_template 'new'
    
    assert_text_field_visible "add_samples_sbeams_user"
  end

  def test_new_affy_platform_gcos_on_sbeams_off_in_site_config_as_customer
    login_as_customer
    # turn off GCOS support
    config = SiteConfig.find(1)
    config.update_attributes(:create_gcos_files => 1,
                             :using_sbeams => 0)
  
    get :new

    assert_response :success
    assert_template 'new'
    
    assert_text_field_visible "add_samples_sbeams_user"
  end

  def test_new_non_affy_platform_gcos_off_in_site_config_as_customer
    login_as_customer
    # turn off GCOS support and turn to non-affy mode
    config = SiteConfig.find(1)
    config.update_attributes(:create_gcos_files => 0,
                             :array_platform => "nonaffy")
  
    get :new

    assert_response :success
    assert_template 'new'
    
    assert_text_field_hidden "add_samples_sbeams_user"
  end

  def test_add_sbeams_on_in_site_config_project_from_dropdown_as_customer
    login_as_customer
    # use new to populate session variables
    get :new
  
    get :add, :add_samples => {:submission_date => "2006-02-12", :number => 2,
                            :project_id => 1, :chip_type_id => 2,
                            :sbeams_user => "Bob"}
    
    # this should have populated the session[:samples] array
    # with two Sample objects containing appropriate info
    @samples = session[:samples]
    assert_equal 2, @samples.size
    assert_equal Date.new(2006, 2, 12), @samples[0].submission_date
    assert_equal 1, @samples[0].project_id
    assert_equal 2, @samples[0].chip_type_id
    assert_equal 2, @samples[0].organism_id
    assert_equal "Bob", @samples[0].sbeams_user
    assert_equal Date.new(2006, 2, 12), @samples[1].submission_date
    assert_equal 1, @samples[1].project_id
    assert_equal 2, @samples[1].chip_type_id   
    assert_equal 2, @samples[1].organism_id
    assert_equal "Bob", @samples[1].sbeams_user
    
    assert_response :success
    assert_template 'add'
    
    @samples = session[:samples]
    assert_equal 2, @samples.size
  end

  def test_add_gcos_off_in_site_config_project_from_dropdown_as_customer
    login_as_customer
    # turn off GCOS support
    config = SiteConfig.find(1)
    config.update_attributes(:create_gcos_files => 0)

    # use test_new to populate session variables
    get :new
  
    get :add, :add_samples => {:submission_date => "2006-02-12", :number => 2,
                            :project_id => 1, :chip_type_id => 2}
    
    # this should have populated the session[:samples] array
    # with two Sample objects containing appropriate info
    @samples = session[:samples]
    assert_equal 2, @samples.size
    assert_equal Date.new(2006, 2, 12), @samples[0].submission_date
    assert_equal 1, @samples[0].project_id
    assert_equal 2, @samples[0].chip_type_id
    assert_equal 2, @samples[0].organism_id
    assert_equal Date.new(2006, 2, 12), @samples[1].submission_date
    assert_equal 1, @samples[1].project_id
    assert_equal 2, @samples[1].chip_type_id   
    assert_equal 2, @samples[1].organism_id
    
    assert_response :success
    assert_template 'add'
    
    @samples = session[:samples]
    assert_equal 2, @samples.size
  end

  def test_add_incomplete_form_project_from_dropdown_as_customer
    login_as_customer
    get :new
  
    get :add, :submission_date => '2006-02-12', :project_id => 1,
        :chip_type_id => 2
    
    # no samples should have been added
    @samples = session[:samples]
    assert_equal @samples.size, 0  
    
    # make sure it complained
    assert_errors
    assert_response :success
    assert_template 'add'
  end

  def test_add_project_from_form_as_customer
    login_as_customer
    num_projects = Project.count

    # use new to populate session variables
    get :new
  
    get :add, :add_samples => {:submission_date => "2006-02-12", :number => 2,
                               :project_id => -1, :chip_type_id => 2,
                               :sbeams_user => "Bob"},
              :project => {:name => "Test Project",
                           :budget => "12340001", :lab_group_id => 2}
    
    # this should have populated the session[:samples] array
    # with two Sample objects containing appropriate info
    @samples = session[:samples]
    assert_equal 2, @samples.size
    assert_equal Date.new(2006, 2, 12), @samples[0].submission_date
    assert_equal 2, @samples[0].chip_type_id
    assert_equal 2, @samples[0].organism_id
    assert_equal "Bob", @samples[0].sbeams_user
    assert_equal Date.new(2006, 2, 12), @samples[1].submission_date
    assert_equal 2, @samples[1].chip_type_id   
    assert_equal 2, @samples[1].organism_id
    assert_equal "Bob", @samples[1].sbeams_user

    # there should also be a new project with the info
    # provided
    assert_equal num_projects + 1, Project.count
    # here's the way to grab the most recently created Project
    new_project = Project.find(:first, :order => "id DESC")
    assert_equal "Test Project", new_project.name
    assert_equal "12340001", new_project.budget
    assert_equal 2, new_project.lab_group_id

    assert_response :success
    assert_template 'add'
    
    @samples = session[:samples]
    assert_equal 2, @samples.size
  end

  def test_add_naming_scheme_selected_as_customer
    login_as_customer

    # select a naming scheme for current user
    current_user = User.find(@request.session[:user].id)
    current_user.current_naming_scheme_id = 1
    current_user.save

    # use new to populate session variables
    get :new
  
    get :add, :add_samples => {:submission_date => "2006-02-12", :number => 2,
                            :project_id => 1, :chip_type_id => 2,
                            :sbeams_user => "Bob"}
    # this should have populated the session[:samples] array
    # with two Sample objects containing appropriate info
    @samples = session[:samples]
    assert_equal 2, @samples.size
    assert_equal Date.new(2006, 2, 12), @samples[0].submission_date
    assert_equal 1, @samples[0].project_id
    assert_equal 2, @samples[0].chip_type_id
    assert_equal 2, @samples[0].organism_id
    assert_equal "Bob", @samples[0].sbeams_user
    assert_equal Date.new(2006, 2, 12), @samples[1].submission_date
    assert_equal 1, @samples[1].project_id
    assert_equal 2, @samples[1].chip_type_id   
    assert_equal 2, @samples[1].organism_id
    assert_equal "Bob", @samples[1].sbeams_user
    
    assert_response :success
    assert_template 'add'
    
    @samples = session[:samples]
    assert_equal 2, @samples.size

    # go back to no naming scheme
    current_user.current_naming_scheme_id = nil
    current_user.save
  end

  def test_create_all_tracking_on_as_customer
    login_as_customer
    num_samples = Sample.count
    num_transactions = ChipTransaction.count
    num_charges = Charge.count

    # use test_add to populate session[:samples] and session[:sample_number]
    test_add_sbeams_on_in_site_config_project_from_dropdown_as_customer

    smpl1 = {:submission_date => '2006-02-12',
            :short_sample_name => 'HlthySmp',
            :sample_name => 'Healthy_Sample',
            :sample_group_name => 'Healthy',
            :organism_id => '1',
            }
    smpl2 = {:submission_date => '2006-02-12',
            :short_sample_name => 'DisSmpl',
            :sample_name => 'Disease_Sample',
            :sample_group_name => 'Disease',
            :organism_id => '1',
            }  

    post :create, :'sample-0' => smpl1, :'sample-1' => smpl2

    assert_response :redirect
    assert_redirected_to :action => 'show'

    # make sure the records made it into the samples table
    assert_equal num_samples + 2,
                 Sample.count
                 
  end

  def test_create_naming_scheme_selected_as_customer
    login_as_customer
    num_samples = Sample.count
    num_transactions = ChipTransaction.count
    num_charges = Charge.count

    # use test_add to populate session[:samples] and session[:sample_number]
    test_add_naming_scheme_selected_as_admin

    smpl1 = {:submission_date => '2006-02-12',
            :short_sample_name => 'HlthySmp',
            :organism_id => '1',
            }
    smpl1_schemed = {:'Strain' => 1,
                    :'Perturbation' => 1,
                    :'Perturbation Time' => 2,
                    }
    smpl2 = {:submission_date => '2006-02-12',
            :short_sample_name => 'DisSmpl',
            :organism_id => '1',
            }  
    smpl2_schemed = {:'Strain' => 2,
                    :'Perturbation' => -1,
                    }

    # select a naming scheme for current user
    current_user = User.find(@request.session[:user].id)
    current_user.current_naming_scheme_id = 1
    current_user.save
    
    # have to set session user before post, even though this isn't
    # necessary before get request
    session[:user] = current_user

    post :create, :'sample-0' => smpl1, :'sample-0_schemed_name' => smpl1_schemed,
                  :'sample-1' => smpl2, :'sample-1_schemed_name' => smpl2_schemed

    # select a naming scheme for current user
    current_user.current_naming_scheme_id = nil
    current_user.save

    assert_response :redirect
    assert_redirected_to :action => 'show'

    # make sure the records made it into the samples table
    assert_equal num_samples + 2,
                 Sample.count
                 
  end

  def test_create_duplicate_sample_name_as_customer
    login_as_customer
    num_samples = Sample.count

    # enter a new set of samples
    get :new

    # add one sample that will have a duplicate submission_date/number  
    get :add, :add_samples => {:submission_date => '2006-02-10', :number => 1,
                            :project_id => 1, :chip_type_id => 2}
    # add another sample with unique submission_date/number
    get :add, :add_samples => {:submission_date => '2006-02-12', :number => 1,
                            :project_id => 1, :chip_type_id => 2}
    
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

  def test_clear_as_customer
    login_as_customer
    # use test_add to populate session[:samples] and session[:sample_number]
    test_add_sbeams_on_in_site_config_project_from_dropdown_as_customer
    
    post :clear
    
    assert_response :redirect
    assert_redirected_to :action => 'new'
    
    assert_equal 0, session[:samples].size
    assert_equal 0, session[:sample_number]
  end

  def test_show_as_customer
    login_as_customer
    get :show  

    assert_response :success
    assert_template 'show'
  end

  def test_edit_as_customer
    login_as_customer
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:sample)
    assert assigns(:sample).valid?
  end

  def test_update_without_naming_scheme_as_customer
    login_as_customer
    post :update, :id => 1, :sample => { :submission_date => '2006-02-09',
                                         :sample_group_name => 'new group' }
    
    sample = Sample.find(1)
    assert_equal Date.new(2006,2,9), sample.submission_date
    assert_equal "new group", sample.sample_group_name
    
    assert_response :redirect
    assert_redirected_to :action => 'list'
  end

  def test_update_with_naming_scheme_as_customer
    login_as_customer

    # select a naming scheme for current user
    current_user = User.find(@request.session[:user].id)
    current_user.current_naming_scheme_id = 1
    current_user.save
    
    post :update, :id => 6, :sample => { :submission_date => '2006-02-09' },
                            :'sample-0_schemed_name' => { :Strain => 1,
                                                          :Perturbation => 3,
                                                          :'Perturbation Time' => 6,
                                                          :Replicate => 7,
                                                          :'Subject Number' => 32235
                                                         } 
    
    sample = Sample.find(6)
    assert_equal Date.new(2006,2,9), sample.submission_date
    assert_equal "wt_HT_024_A_32235", sample.sample_name
    assert_equal "wt_HT_024", sample.sample_group_name
    
    sample_terms = SampleTerm.find(:all, :conditions => ["sample_id = ?", 6],
                                   :order => "term_order ASC")
    assert_equal 4, sample_terms.size
    expected_terms = [1,3,6,7]
    for i in 0..expected_terms.size-1
      assert_equal expected_terms[i], sample_terms[i].naming_term_id
    end
    
    assert_response :redirect
    assert_redirected_to :action => 'list'
  end

  def test_update_locked_without_naming_scheme_as_customer
    login_as_customer
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

  def test_destroy_submitted_sample_as_customer
    login_as_customer
    assert_not_nil Sample.find(1)

    @request.env["HTTP_REFERER"] = "/samples/list"
    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to "samples/list"

    assert_raise(ActiveRecord::RecordNotFound) {
      Sample.find(1)
    }
  end

  # Customers should not be able to delete hybridized sample records
  def test_destroy_hybridized_sample_as_customer
    login_as_customer
    assert_not_nil Sample.find(2)

    @request.env["HTTP_REFERER"] = "/samples/list"
    post :destroy, :id => 2
    assert_response :success
    assert_template 'list'
    assert_flash_warning

    assert_not_nil Sample.find(2)
  end

end

  # choose a couple of total RNA traces and request labeling
  def test_submit_traces_request_labeling_total_RNA_only_as_customer
    login_as_customer
    
    post :submit_traces, :commit => 'Request Labeling',
                         :selected_traces => {'1' => '1', '2' => '1'}
                         
    assert_no_flash_warning
    assert_response :success
    assert_template 'new_from_traces'
  end

  # choose a couple of total RNA and cRNA traces
  def test_submit_traces_request_labeling_total_RNA_and_others_as_customer
    login_as_customer
    
    post :submit_traces, :commit => 'Request Labeling',
                         :selected_traces => {'1' => '1', '2' => '1', '10' => '1'}

    assert_flash_warning
    assert_response :success
    assert_template 'new_from_traces'
  end

  # choose a couple of total RNA traces and request labeling, then
  # create samples
  def test_create_from_traces_from_labeling_request_as_customer
    login_as_customer
    num_samples = Sample.count
    
    # use submit_traces to populate session[:samples]
    test_submit_traces_request_labeling_total_RNA_only_as_customer
              
    post :create_from_traces, :add_samples => {:submission_date => '2006-11-29',
                                               :chip_type_id => 1,
                                               :sbeams_user => 'janderson',
                                               :project_id => 1},
                              :'sample-0' => {:short_sample_name => 'wA',
                                              :sample_name => 'WT_A',
                                              :sample_group_name => 'WT'},
                              :'sample-1' => {:short_sample_name => 'mA',
                                              :sample_name => 'Mut_A',
                                              :sample_group_name => 'Mut'}
    
    assert_response :redirect
    assert_redirected_to :action => 'show'

    # make sure the records made it into the samples table
    assert_equal num_samples + 2,
                 Sample.count
  end
  
  # choose a couple of total RNA traces and request labeling, then
  # create samples, then select cRNA and fragmented traces and request
  # hybridization
  def test_submit_traces_from_labeling_request_as_customer
    login_as_customer

    post :submit_traces, :commit => 'Request Labeling',
                         :selected_traces => {'6' => '1', '7' => '1'}
    
    post :create_from_traces, :add_samples => {:submission_date => '2006-11-28',
                                               :chip_type_id => 1,
                                               :sbeams_user => 'janderson',
                                               :project_id => 1},
                              :'sample-0' => {:short_sample_name => 'c1',
                                              :sample_name => 'Control_1',
                                              :sample_group_name => 'con'},
                              :'sample-1' => {:short_sample_name => 'c2',
                                              :sample_name => 'Control_2',
                                              :sample_group_name => 'con'}
        
    post :submit_traces, :commit => 'Request Hybridization',
                         :selected_traces => {'10' => '1', '14' => '1',
                                              '11' => '1', '15' => '1'}

    assert_response :success
    assert_template 'match_traces'
  end

  # choose a couple of total RNA traces and request labeling, then
  # create samples, select cRNA and fragmented traces and request
  # hybridization and finally submit the matched traces/samples
  def test_submit_matched_traces_from_labeling_request_as_customer
    login_as_customer
      
    test_submit_traces_from_labeling_request_as_customer

    num_samples = Sample.count
    
    # find samples that were created
    s1 = Sample.find(:first, :conditions => ["starting_quality_trace_id = 6"])
    s2 = Sample.find(:first, :conditions => ["starting_quality_trace_id = 7"])
    
    post :submit_matched_traces, :num_samples => '2',
                                 :'sample-0' => {:starting_quality_trace_id => '6',
                                                 :amplified_quality_trace_id => '10',
                                                 :fragmented_quality_trace_id => '14',
                                                 :id => s1.id},
                                 :'sample-1' => {:starting_quality_trace_id => '7',
                                                 :amplified_quality_trace_id => '11',
                                                 :fragmented_quality_trace_id => '15',
                                                 :id => s2.id}

    assert_response :redirect
    assert_redirected_to :action => 'show'
    
    # no new samples should have been created during submit_matched_traces
    assert_equal num_samples, Sample.count
    
    # verify that the samples are now tagged with the correct trace ids
    s1 = Sample.find(:first, :conditions => ["starting_quality_trace_id = 6"])
    s2 = Sample.find(:first, :conditions => ["starting_quality_trace_id = 7"])
    assert_equal 10, s1.amplified_quality_trace_id
    assert_equal 14, s1.fragmented_quality_trace_id
    assert_equal 11, s2.amplified_quality_trace_id
    assert_equal 15, s2.fragmented_quality_trace_id
  end

  # choose a set of traces (total RNA/cRNA/fragmented),
  # all with the same name, and request hybridization
  def test_submit_traces_request_hybridization_as_customer
    login_as_customer
    
    post :submit_traces, :commit => 'Request Hybridization',
                         :selected_traces => {'6' => '1', '10' => '1', '14' => '1'}

    assert_response :success
    assert_template 'match_traces'
    
    # should have fields for one sample
    assert_tag :tag => 'select', :attributes => { :id => 'sample-0_starting_quality_trace_id' }

    # but not two samples
    assert_no_tag :tag => 'select', :attributes => { :id => 'sample-1_starting_quality_trace_id' }
  end

  # choose a set of traces (total RNA/cRNA/fragmented),
  # all with the same name, request hybridization and then
  # submit matched up traces
  def test_submit_matched_traces_from_hybridization_request_as_customer
    login_as_customer
    
    test_submit_traces_request_hybridization_as_customer
    
    post :submit_matched_traces, :num_samples => '1',
                                 :'sample-0' => {:starting_quality_trace_id => '6',
                                                 :amplified_quality_trace_id => '10',
                                                 :fragmented_quality_trace_id => '14',
                                                 :id => '0'}
    
    assert_response :success
    assert_template 'new_from_traces'
  end

  # choose a set of traces (total RNA/cRNA/fragmented),
  # all with the same name, request hybridization,
  # submit matched up traces and then create samples
  def test_create_from_traces_from_hybridization_request_as_customer
    login_as_customer

    num_samples = Sample.count
    
    # use submit_traces to populate session[:samples]
    test_submit_matched_traces_from_hybridization_request_as_customer
              
    post :create_from_traces, :add_samples => {:submission_date => '2006-11-29',
                                               :chip_type_id => 1,
                                               :sbeams_user => 'janderson',
                                               :project_id => 1},
                              :'sample-0' => {:short_sample_name => 'c1',
                                              :sample_name => 'Control_1',
                                              :sample_group_name => 'con'}
    
    assert_response :redirect
    assert_redirected_to :action => 'show'

    # make sure the records made it into the samples table
    assert_equal num_samples + 1,
                 Sample.count
  end

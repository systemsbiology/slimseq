require File.dirname(__FILE__) + '/../test_helper'

class BioanalyzerRunTest < Test::Unit::TestCase
  fixtures :lab_groups

  def set_bioanalyzer_pickup_directory
    # point site settings at test set of bioanalyzer files
    site_config = SiteConfig.find(1)
    site_config.bioanalyzer_pickup = "#{RAILS_ROOT}/test/fixtures/bioanalyzer_files"
    site_config.save
    
    # trash the Bioanalyzer data that's already loaded
    BioanalyzerRun.find(:all).each do |r|
      r.destroy
    end
  end

  def test_import_new
    set_bioanalyzer_pickup_directory
    
    num_bioanalyzer_runs = BioanalyzerRun.count
    num_quality_traces = QualityTrace.count
    
    BioanalyzerRun.import_new

    assert_equal num_bioanalyzer_runs + 2, BioanalyzerRun.count
    # 12 samples + ladder from one chip, and 2 samples only
    # from 2nd chip--ladder ownership doesn't make sense for
    # split chips, so it isn't saved
    assert_equal num_quality_traces + 17, QualityTrace.count
  end
  
  # ensure that import calls subsequent to the initial one that
  # find the data don't reimport duplicate runs/traces
  def test_import_new_twice
    set_bioanalyzer_pickup_directory
    
    num_bioanalyzer_runs = BioanalyzerRun.count
    num_quality_traces = QualityTrace.count
    
    BioanalyzerRun.import_new

    assert_equal num_bioanalyzer_runs + 2, BioanalyzerRun.count
    assert_equal num_quality_traces + 17, QualityTrace.count

    BioanalyzerRun.import_new

    assert_equal num_bioanalyzer_runs + 2, BioanalyzerRun.count
    assert_equal num_quality_traces + 17, QualityTrace.count
  end
end

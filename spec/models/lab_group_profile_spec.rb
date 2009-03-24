require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe LabGroupProfile do
  fixtures :site_config

  it "should provide a destroy warning" do
    lab_group_profile = LabGroupProfile.create(:lab_group_id => 3)

    ChargeSet.should_receive(:find).and_return( [mock_model(ChargeSet), mock_model(ChargeSet)] )
    Project.should_receive(:find).and_return( [mock_model(Project)] )

    lab_group_profile.destroy_warning.should ==
      "Destroying this lab group will also destroy:\n" + 
           "2 charge set(s)\n" +
           "1 project(s)\n" +
           "Are you sure you want to destroy it?"
  end

  it "should provide a detail hash of attributes" do
    lab_group_profile = LabGroupProfile.create(
      :file_folder => "yeast",
      :lab_group_id => 3
    )
    Project.should_receive(:find).
      with(:all, :conditions => {:lab_group_id => 3}).
      and_return( [mock_model(Project, :lab_group_id => 3, :id => 1)] )

    lab_group_profile.detail_hash.should == {
      :file_folder => "yeast",
      :project_uris => ["http://example.com/projects/1"]
    }
  end
end

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Project" do
  fixtures :projects, :samples, :charge_sets, :projects

  it "should provide a hash of summary attributes" do
    project = create_project(:name => "Fungus Project")

    project.summary_hash.should == {
      :id => project.id,
      :name => "Fungus Project",
      :updated_at => project.updated_at,
      :uri => "http://example.com/projects/#{project.id}"
    }
  end

  it "should provide a hash of detailed attributes" do
    lab_group = mock("LabGroup", :id => 3, :name => "Fungus Group")

    project = create_project(
      :name => "Fungus Project",
      :file_folder => "fungus"
    )
    project.stub!(:lab_group_id).and_return(3)
    project.stub!(:lab_group).and_return(lab_group)

    sample_mixture_1 = create_sample_mixture(:project => project)
    sample_mixture_2 = create_sample_mixture(:project => project)
    sample_1 = create_sample(:sample_mixture => sample_mixture_1)
    sample_2 = create_sample(:sample_mixture => sample_mixture_2)

    project.detail_hash.should == {
      :id => project.id,
      :name => "Fungus Project",
      :file_folder => "fungus",
      :lab_group => "Fungus Group",
      :lab_group_uri => "http://example.com/lab_groups/#{lab_group.id}",
      :updated_at => project.updated_at,
      :sample_uris => ["http://example.com/samples/#{sample_1.id}",
                        "http://example.com/samples/#{sample_2.id}"]
    }
  end

  it "should provide projects associated with a lab group" do
    lab_group_1 = mock_model(LabGroup, :destroyed? => false)
    lab_group_2 = mock_model(LabGroup, :destroyed? => false)
    project_1 = create_project(:lab_group => lab_group_1)
    project_2 = create_project(:lab_group => lab_group_1)
    project_3 = create_project(:lab_group => lab_group_2)

    Project.for_lab_group(lab_group_1).should == [project_1, project_2]
  end
end

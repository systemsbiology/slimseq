require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "LabGroup" do
  fixtures :lab_groups, :samples, :charge_sets, :projects

  it "should provide an accurate destroy warning" do
    expected_warning = "Destroying this lab group will also destroy:\n" + 
                       "3 charge set(s)\n" +
                       "2 project(s)\n" +
                       "Are you sure you want to destroy it?"

    group = LabGroup.find( lab_groups(:gorilla_group).id )   
    group.destroy_warning.should == expected_warning
  end

  it "should provide a hash of summary attributes" do
    lab_group = create_lab_group(:name => "Fungus Group")

    lab_group.summary_hash.should == {
      :id => lab_group.id,
      :name => "Fungus Group",
      :updated_at => lab_group.updated_at,
      :uri => "http://example.com/lab_groups/#{lab_group.id}"
    }
  end

  it "should provide a hash of detailed attributes" do
    lab_group = create_lab_group(
      :name => "Fungus Group",
      :file_folder => "fungus"
    )
    user_1 = create_user(:lab_groups => [lab_group])
    user_2 = create_user(:lab_groups => [lab_group])
    project_1 = create_project(:lab_group => lab_group)
    project_2 = create_project(:lab_group => lab_group)

    lab_group.detail_hash.should == {
      :id => lab_group.id,
      :name => "Fungus Group",
      :file_folder => "fungus",
      :updated_at => lab_group.updated_at,
      :user_uris => ["http://example.com/users/#{user_1.id}",
                     "http://example.com/users/#{user_2.id}"],
      :project_uris => ["http://example.com/projects/#{project_1.id}",
                        "http://example.com/projects/#{project_2.id}"]
    }
  end
end

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "User" do

  it "should provide a hash of summary attributes" do
    user = create_user(:login => "jsmith")

    user.summary_hash.should == {
      :id => user.id,
      :login => "jsmith",
      :updated_at => user.updated_at,
      :uri => "http://example.com/users/#{user.id}"
    }
  end

  it "should provide a hash of detailed attributes" do
    lab_group_1 = create_lab_group
    lab_group_2 = create_lab_group

    user = create_user(
      :login => "jsmith",
      :email => "jsmith@example.com",
      :firstname => "Joe",
      :lastname => "Smith",
      :lab_groups => [lab_group_1, lab_group_2]
    )

    user.detail_hash.should == {
      :id => user.id,
      :login => "jsmith",
      :email => "jsmith@example.com",
      :firstname => "Joe",
      :lastname => "Smith",
      :updated_at => user.updated_at,
      :lab_group_uris => ["http://example.com/lab_groups/#{lab_group_1.id}",
                          "http://example.com/lab_groups/#{lab_group_2.id}"]
    }
  end

end
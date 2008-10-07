require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FlowCellsController do
  describe "route generation" do
    it "should map #index" do
      route_for(:controller => "flow_cells", :action => "index").should == "/flow_cells"
    end
  
    it "should map #new" do
      route_for(:controller => "flow_cells", :action => "new").should == "/flow_cells/new"
    end
  
    it "should map #show" do
      route_for(:controller => "flow_cells", :action => "show", :id => 1).should == "/flow_cells/1"
    end
  
    it "should map #edit" do
      route_for(:controller => "flow_cells", :action => "edit", :id => 1).should == "/flow_cells/1/edit"
    end
  
    it "should map #update" do
      route_for(:controller => "flow_cells", :action => "update", :id => 1).should == "/flow_cells/1"
    end
  
    it "should map #destroy" do
      route_for(:controller => "flow_cells", :action => "destroy", :id => 1).should == "/flow_cells/1"
    end
  end

  describe "route recognition" do
    it "should generate params for #index" do
      params_from(:get, "/flow_cells").should == {:controller => "flow_cells", :action => "index"}
    end
  
    it "should generate params for #new" do
      params_from(:get, "/flow_cells/new").should == {:controller => "flow_cells", :action => "new"}
    end
  
    it "should generate params for #create" do
      params_from(:post, "/flow_cells").should == {:controller => "flow_cells", :action => "create"}
    end
  
    it "should generate params for #show" do
      params_from(:get, "/flow_cells/1").should == {:controller => "flow_cells", :action => "show", :id => "1"}
    end
  
    it "should generate params for #edit" do
      params_from(:get, "/flow_cells/1/edit").should == {:controller => "flow_cells", :action => "edit", :id => "1"}
    end
  
    it "should generate params for #update" do
      params_from(:put, "/flow_cells/1").should == {:controller => "flow_cells", :action => "update", :id => "1"}
    end
  
    it "should generate params for #destroy" do
      params_from(:delete, "/flow_cells/1").should == {:controller => "flow_cells", :action => "destroy", :id => "1"}
    end
  end
end

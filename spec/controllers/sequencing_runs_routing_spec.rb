require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SequencingRunsController do
  describe "route generation" do
    it "should map #index" do
      route_for(:controller => "sequencing_runs", :action => "index").should == "/sequencing_runs"
    end
  
    it "should map #new" do
      route_for(:controller => "sequencing_runs", :action => "new").should == "/sequencing_runs/new"
    end
  
    it "should map #show" do
      route_for(:controller => "sequencing_runs", :action => "show", :id => 1).should == "/sequencing_runs/1"
    end
  
    it "should map #edit" do
      route_for(:controller => "sequencing_runs", :action => "edit", :id => 1).should == "/sequencing_runs/1/edit"
    end
  
    it "should map #update" do
      route_for(:controller => "sequencing_runs", :action => "update", :id => 1).should == "/sequencing_runs/1"
    end
  
    it "should map #destroy" do
      route_for(:controller => "sequencing_runs", :action => "destroy", :id => 1).should == "/sequencing_runs/1"
    end

    it "should map #default_output_paths" do
      route_for(:controller => "sequencing_runs", :action => "default_output_paths", :id => 1).should == "/sequencing_runs/default_output_paths/1"
    end
  end

  describe "route recognition" do
    it "should generate params for #index" do
      params_from(:get, "/sequencing_runs").should == {:controller => "sequencing_runs", :action => "index"}
    end
  
    it "should generate params for #new" do
      params_from(:get, "/sequencing_runs/new").should == {:controller => "sequencing_runs", :action => "new"}
    end
  
    it "should generate params for #create" do
      params_from(:post, "/sequencing_runs").should == {:controller => "sequencing_runs", :action => "create"}
    end
  
    it "should generate params for #show" do
      params_from(:get, "/sequencing_runs/1").should == {:controller => "sequencing_runs", :action => "show", :id => "1"}
    end
  
    it "should generate params for #edit" do
      params_from(:get, "/sequencing_runs/1/edit").should == {:controller => "sequencing_runs", :action => "edit", :id => "1"}
    end
  
    it "should generate params for #update" do
      params_from(:put, "/sequencing_runs/1").should == {:controller => "sequencing_runs", :action => "update", :id => "1"}
    end
  
    it "should generate params for #destroy" do
      params_from(:delete, "/sequencing_runs/1").should == {:controller => "sequencing_runs", :action => "destroy", :id => "1"}
    end

    it "should generate params for #default_output_paths" do
      params_from(:get, "/sequencing_runs/default_output_path1").should == {:controller => "sequencing_runs", :action => "default_output_paths", :id => "1"}
    end
  end
end

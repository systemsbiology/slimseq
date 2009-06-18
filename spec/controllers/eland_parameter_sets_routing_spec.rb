require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ElandParameterSetsController do
  describe "route generation" do
    it "should map #index" do
      route_for(:controller => "eland_parameter_sets", :action => "index").should == "/eland_parameter_sets"
    end
  
    it "should map #new" do
      route_for(:controller => "eland_parameter_sets", :action => "new").should == "/eland_parameter_sets/new"
    end
  
    it "should map #show" do
      route_for(:controller => "eland_parameter_sets", :action => "show", :id => 1).should == "/eland_parameter_sets/1"
    end
  
    it "should map #edit" do
      route_for(:controller => "eland_parameter_sets", :action => "edit", :id => 1).should == "/eland_parameter_sets/1/edit"
    end
  
    it "should map #update" do
      route_for(:controller => "eland_parameter_sets", :action => "update", :id => 1).should == "/eland_parameter_sets/1"
    end
  
    it "should map #destroy" do
      route_for(:controller => "eland_parameter_sets", :action => "destroy", :id => 1).should == "/eland_parameter_sets/1"
    end
  end

  describe "route recognition" do
    it "should generate params for #index" do
      params_from(:get, "/eland_parameter_sets").should == {:controller => "eland_parameter_sets", :action => "index"}
    end
  
    it "should generate params for #new" do
      params_from(:get, "/eland_parameter_sets/new").should == {:controller => "eland_parameter_sets", :action => "new"}
    end
  
    it "should generate params for #create" do
      params_from(:post, "/eland_parameter_sets").should == {:controller => "eland_parameter_sets", :action => "create"}
    end
  
    it "should generate params for #show" do
      params_from(:get, "/eland_parameter_sets/1").should == {:controller => "eland_parameter_sets", :action => "show", :id => "1"}
    end
  
    it "should generate params for #edit" do
      params_from(:get, "/eland_parameter_sets/1/edit").should == {:controller => "eland_parameter_sets", :action => "edit", :id => "1"}
    end
  
    it "should generate params for #update" do
      params_from(:put, "/eland_parameter_sets/1").should == {:controller => "eland_parameter_sets", :action => "update", :id => "1"}
    end
  
    it "should generate params for #destroy" do
      params_from(:delete, "/eland_parameter_sets/1").should == {:controller => "eland_parameter_sets", :action => "destroy", :id => "1"}
    end
  end
end

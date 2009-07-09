require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ReferenceGenomesController do
  describe "route generation" do

    it "should map { :controller => 'reference_genomes', :action => 'index' } to /reference_genomes" do
      route_for(:controller => "reference_genomes", :action => "index").should == "/reference_genomes"
    end
  
    it "should map { :controller => 'reference_genomes', :action => 'new' } to /reference_genomes/new" do
      route_for(:controller => "reference_genomes", :action => "new").should == "/reference_genomes/new"
    end
  
    it "should map { :controller => 'reference_genomes', :action => 'show', :id => 1 } to /reference_genomes/1" do
      route_for(:controller => "reference_genomes", :action => "show", :id => "1").should == "/reference_genomes/1"
    end
  
    it "should map { :controller => 'reference_genomes', :action => 'edit', :id => 1 } to /reference_genomes/1/edit" do
      route_for(:controller => "reference_genomes", :action => "edit", :id => "1").should == "/reference_genomes/1/edit"
    end
  
    it "should map { :controller => 'reference_genomes', :action => 'update', :id => 1} to /reference_genomes/1" do
      route_for(:controller => "reference_genomes", :action => "update", :id => "1").
        should == {:path => "/reference_genomes/1", :method => :put}
    end
  
    it "should map { :controller => 'reference_genomes', :action => 'destroy', :id => 1} to /reference_genomes/1" do
      route_for(:controller => "reference_genomes", :action => "destroy", :id => "1").
        should == {:path => "/reference_genomes/1", :method => :delete}
    end
  end

  describe "route recognition" do

    it "should generate params { :controller => 'reference_genomes', action => 'index' } from GET /reference_genomes" do
      params_from(:get, "/reference_genomes").should == {:controller => "reference_genomes", :action => "index"}
    end
  
    it "should generate params { :controller => 'reference_genomes', action => 'new' } from GET /reference_genomes/new" do
      params_from(:get, "/reference_genomes/new").should == {:controller => "reference_genomes", :action => "new"}
    end
  
    it "should generate params { :controller => 'reference_genomes', action => 'create' } from POST /reference_genomes" do
      params_from(:post, "/reference_genomes").should == {:controller => "reference_genomes", :action => "create"}
    end
  
    it "should generate params { :controller => 'reference_genomes', action => 'show', id => '1' } from GET /reference_genomes/1" do
      params_from(:get, "/reference_genomes/1").should == {:controller => "reference_genomes", :action => "show", :id => "1"}
    end
  
    it "should generate params { :controller => 'reference_genomes', action => 'edit', id => '1' } from GET /reference_genomes/1;edit" do
      params_from(:get, "/reference_genomes/1/edit").should == {:controller => "reference_genomes", :action => "edit", :id => "1"}
    end
  
    it "should generate params { :controller => 'reference_genomes', action => 'update', id => '1' } from PUT /reference_genomes/1" do
      params_from(:put, "/reference_genomes/1").should == {:controller => "reference_genomes", :action => "update", :id => "1"}
    end
  
    it "should generate params { :controller => 'reference_genomes', action => 'destroy', id => '1' } from DELETE /reference_genomes/1" do
      params_from(:delete, "/reference_genomes/1").should == {:controller => "reference_genomes", :action => "destroy", :id => "1"}
    end
  end
end

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/controller_spec_helper.rb')

describe ProjectsController do

  before(:each) do
    login_as_staff
  end
  
  describe "responding to GET index" do

    before(:each) do
      project_1 = mock_model(Project)
      project_2 = mock_model(Project)
      project_1.should_receive(:summary_hash).and_return( {:n => 1} )
      project_2.should_receive(:summary_hash).and_return( {:n => 2} )
      @projects = [project_1, project_2]
    end
    
    describe "with mime type of xml" do
  
      it "should render all projects as xml" do
        request.env["HTTP_ACCEPT"] = "application/xml"
        Project.should_receive(:find).with(:all, :order => "name ASC").and_return(@projects)
        get :index
        response.body.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
          "<records type=\"array\">\n  <record>\n    <n type=\"integer\">1</n>\n  " +
          "</record>\n  <record>\n    <n type=\"integer\">2</n>\n  </record>\n</records>\n"
      end
    
    end

    describe "with mime type of json" do
  
      it "should render flow cell lane summaries as json" do

        
        request.env["HTTP_ACCEPT"] = "application/json"
        Project.should_receive(:find).with(:all, :order => "name ASC").
          and_return(@projects)
        get :index
        response.body.should == "[{\"n\":1},{\"n\":2}]"
      end
    
    end

  end

  describe "responding to GET show" do
    
    before(:each) do
      @project = mock_model(Project)
      @project.should_receive(:detail_hash).and_return( {:n => 1} )      
    end
    
    describe "with mime type of xml" do

      it "should render the requested project as xml" do
        request.env["HTTP_ACCEPT"] = "application/xml"
        Project.should_receive(:find).with("37").and_return(@project)
        get :show, :id => "37"
        response.body.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<hash>\n  " +
          "<n type=\"integer\">1</n>\n</hash>\n"
      end

    end
    
    describe "with mime type of json" do
  
      it "should render the flow cell lane detail as json" do
        request.env["HTTP_ACCEPT"] = "application/json"
        Project.should_receive(:find).with("37").and_return(@project)
        get :show, :id => 37
        response.body.should == "{\"n\":1}"
      end
    
    end
    
  end

end

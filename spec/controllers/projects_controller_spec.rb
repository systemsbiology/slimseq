require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/controller_spec_helper.rb')

describe ProjectsController do

  before(:each) do
    login_as_staff
  end
  
  describe "responding to GET index" do

    before(:each) do
      @project_1 = mock_model(Project)
      @project_2 = mock_model(Project)
      @projects = [@project_1, @project_2]
    end

    describe "with a mime type of html" do

      it "should render all the projects as html" do
        Project.should_receive(:find).with(:all, :order => "name ASC").and_return(@projects)
        get :index
        response.should be_success
        response.should render_template('index')
        assigns[:projects].should == @projects
      end
      
    end

    describe "with mime type of xml" do
  
      it "should render all projects as xml" do
        @project_1.should_receive(:summary_hash).and_return( {:n => 1} )
        @project_2.should_receive(:summary_hash).and_return( {:n => 2} )

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
        @project_1.should_receive(:summary_hash).and_return( {:n => 1} )
        @project_2.should_receive(:summary_hash).and_return( {:n => 2} )
        
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

  describe "handling GET /projects/new" do

    before(:each) do
      @current_user.should_receive(:accessible_lab_groups)
      
      @project = mock_model(Project)
      Project.stub!(:new).and_return(@project)
    end

    def do_get
      get :new
    end

    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render new template" do
      do_get
      response.should render_template('new')
    end

    it "should create an new project" do
      Project.should_receive(:new).and_return(@project)
      do_get
    end

    it "should not save the new project" do
      @project.should_not_receive(:save)
      do_get
    end

    it "should assign the new project for the view" do
      do_get
      assigns[:project].should equal(@project)
    end
  end

  describe "handling GET /projects/new_inline" do

    before(:each) do
      @current_user.should_receive(:accessible_lab_groups)

      @project = mock_model(Project)
      Project.stub!(:new).and_return(@project)
    end

    def do_get
      get :new_inline
    end

    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render new_inline partial" do
      do_get
      response.should render_template('_new_inline')
    end

    it "should create an new project" do
      Project.should_receive(:new).and_return(@project)
      do_get
    end

    it "should not save the new project" do
      @project.should_not_receive(:save)
      do_get
    end

    it "should assign the new project for the view" do
      do_get
      assigns[:project].should equal(@project)
    end
  end

  describe "handling GET /projects/1/edit" do

    before(:each) do
      @current_user.should_receive(:accessible_lab_groups)
      
      @project = mock_model(Project)
      Project.stub!(:find).and_return(@project)
    end

    def do_get
      get :edit, :id => "1"
    end

    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render edit template" do
      do_get
      response.should render_template('edit')
    end

    it "should find the project requested" do
      Project.should_receive(:find).and_return(@project)
      do_get
    end

    it "should assign the found Project for the view" do
      do_get
      assigns[:project].should equal(@project)
    end
  end

  describe "handling POST /projects" do

    before(:each) do
      @current_user.should_receive(:accessible_lab_groups)

      @project = mock_model(Project, :to_param => "1")
      Project.stub!(:new).and_return(@project)
    end

    describe "with successful save" do

      def do_post
        @project.should_receive(:save).and_return(true)
        post :create, :project => {}
      end

      it "should create a new project" do
        Project.should_receive(:new).with({}).and_return(@project)
        do_post
      end

      it "should redirect to the project index" do
        do_post
        response.should redirect_to(projects_url)
      end

    end

    describe "with failed save" do

      def do_post
        @project.should_receive(:save).and_return(false)
        post :create, :project => {}
      end

      it "should re-render 'new'" do
        do_post
        response.should render_template('new')
      end

    end
  end

  describe "handling POST /projects/create_inline" do

    before(:each) do
      @current_user.should_receive(:accessible_lab_groups)

      @project = mock_model(Project, :to_param => "1")
      Project.stub!(:new).and_return(@project)
      @sample_set = mock_model(SampleSet)
      SampleSet.stub!(:new).and_return(@sample_set)
    end

    describe "with successful save" do

      before(:each) do
        @current_user.should_receive(:accessible_projects)
      end

      def do_post
        @project.should_receive(:save).and_return(true)
        post :create_inline, :project => {"name" => "My Project"}
      end

      it "should create a new project" do
        Project.should_receive(:new).and_return(@project)
        do_post
      end

      it "should make a new sample set that pointed at this project" do
        SampleSet.should_receive(:new).
          with(:project_id => @project.id).
          and_return(@sample_set)
        do_post
      end

      it "should render the sample_sets/projects partial" do
        do_post
        response.should render_template('sample_sets/_projects')
      end

    end

    describe "with failed save" do

      def do_post
        @project.should_receive(:save).and_return(false)
        post :create_inline, :project => {}
      end

      it "should re-render 'new_inline'" do
        do_post
        response.should render_template('new_inline')
      end

    end
  end

  describe "handling PUT /projects/1" do

    before(:each) do
      @current_user.should_receive(:accessible_lab_groups)

      @project = mock_model(Project, :to_param => "1")
      Project.stub!(:find).and_return(@project)
    end

    describe "with successful update" do

      def do_put
        @project.should_receive(:update_attributes).and_return(true)
        put :update, :id => "1"
      end

      it "should find the project requested" do
        Project.should_receive(:find).with("1").and_return(@project)
        do_put
      end

      it "should update the found project" do
        do_put
        assigns(:project).should equal(@project)
      end

      it "should assign the found project for the view" do
        do_put
        assigns(:project).should equal(@project)
      end

      it "should redirect to the project index" do
        do_put
        response.should redirect_to(projects_url)
      end

    end

    describe "with failed update" do

      def do_put
        @project.should_receive(:update_attributes).and_return(false)
        put :update, :id => "1"
      end

      it "should re-render 'edit'" do
        do_put
        response.should render_template('edit')
      end

    end
  end

  describe "handling DELETE /projects/1" do

    before(:each) do
      @project = mock_model(Project, :destroy => true)
      Project.stub!(:find).and_return(@project)
    end

    def do_delete
      delete :destroy, :id => "1"
    end

    it "should find the project requested" do
      Project.should_receive(:find).with("1").and_return(@project)
      do_delete
    end

    it "should call destroy on the found project" do
      @project.should_receive(:destroy)
      do_delete
    end

    it "should redirect to the projects list" do
      do_delete
      response.should redirect_to(projects_url)
    end
  end
end

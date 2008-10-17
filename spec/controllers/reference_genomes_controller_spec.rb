require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ReferenceGenomesController do
  describe "handling GET /reference_genomes" do

    before(:each) do
      @reference_genome = mock_model(ReferenceGenome)
      ReferenceGenome.stub!(:find).and_return([@reference_genome])
    end
  
    def do_get
      get :index
    end
  
    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render index template" do
      do_get
      response.should render_template('index')
    end
  
    it "should find all reference_genomes" do
      ReferenceGenome.should_receive(:find).with(:all).and_return([@reference_genome])
      do_get
    end
  
    it "should assign the found reference_genomes for the view" do
      do_get
      assigns[:reference_genomes].should == [@reference_genome]
    end
  end

  describe "handling GET /reference_genomes.xml" do

    before(:each) do
      @reference_genomes = mock("Array of ReferenceGenomes", :to_xml => "XML")
      ReferenceGenome.stub!(:find).and_return(@reference_genomes)
    end
  
    def do_get
      @request.env["HTTP_ACCEPT"] = "application/xml"
      get :index
    end
  
    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should find all reference_genomes" do
      ReferenceGenome.should_receive(:find).with(:all).and_return(@reference_genomes)
      do_get
    end
  
    it "should render the found reference_genomes as xml" do
      @reference_genomes.should_receive(:to_xml).and_return("XML")
      do_get
      response.body.should == "XML"
    end
  end

#  describe "handling GET /reference_genomes/1" do
#
#    before(:each) do
#      @reference_genome = mock_model(ReferenceGenome)
#      ReferenceGenome.stub!(:find).and_return(@reference_genome)
#    end
#  
#    def do_get
#      get :show, :id => "1"
#    end
#
#    it "should be successful" do
#      do_get
#      response.should be_success
#    end
#  
#    it "should render show template" do
#      do_get
#      response.should render_template('show')
#    end
#  
#    it "should find the reference_genome requested" do
#      ReferenceGenome.should_receive(:find).with("1").and_return(@reference_genome)
#      do_get
#    end
#  
#    it "should assign the found reference_genome for the view" do
#      do_get
#      assigns[:reference_genome].should equal(@reference_genome)
#    end
#  end

  describe "handling GET /reference_genomes/1.xml" do

    before(:each) do
      @reference_genome = mock_model(ReferenceGenome, :to_xml => "XML")
      ReferenceGenome.stub!(:find).and_return(@reference_genome)
    end
  
    def do_get
      @request.env["HTTP_ACCEPT"] = "application/xml"
      get :show, :id => "1"
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should find the reference_genome requested" do
      ReferenceGenome.should_receive(:find).with("1").and_return(@reference_genome)
      do_get
    end
  
    it "should render the found reference_genome as xml" do
      @reference_genome.should_receive(:to_xml).and_return("XML")
      do_get
      response.body.should == "XML"
    end
  end

  describe "handling GET /reference_genomes/1.json" do

    before(:each) do
      @reference_genome = mock_model(ReferenceGenome, :to_json => "JSON")
      ReferenceGenome.stub!(:find).and_return(@reference_genome)
    end
  
    def do_get
      @request.env["HTTP_ACCEPT"] = "application/json"
      get :show, :id => "1"
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should find the reference_genome requested" do
      ReferenceGenome.should_receive(:find).with("1").and_return(@reference_genome)
      do_get
    end
  
    it "should render the found reference_genome as json" do
      @reference_genome.should_receive(:to_json).and_return("JSON")
      do_get
      response.body.should == "JSON"
    end
  end
  
  describe "handling GET /reference_genomes/new" do

    before(:each) do
      @reference_genome = mock_model(ReferenceGenome)
      ReferenceGenome.stub!(:new).and_return(@reference_genome)
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
  
    it "should create an new reference_genome" do
      ReferenceGenome.should_receive(:new).and_return(@reference_genome)
      do_get
    end
  
    it "should not save the new reference_genome" do
      @reference_genome.should_not_receive(:save)
      do_get
    end
  
    it "should assign the new reference_genome for the view" do
      do_get
      assigns[:reference_genome].should equal(@reference_genome)
    end
  end

  describe "handling GET /reference_genomes/1/edit" do

    before(:each) do
      @reference_genome = mock_model(ReferenceGenome)
      ReferenceGenome.stub!(:find).and_return(@reference_genome)
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
  
    it "should find the reference_genome requested" do
      ReferenceGenome.should_receive(:find).and_return(@reference_genome)
      do_get
    end
  
    it "should assign the found ReferenceGenome for the view" do
      do_get
      assigns[:reference_genome].should equal(@reference_genome)
    end
  end

  describe "handling POST /reference_genomes" do

    before(:each) do
      @reference_genome = mock_model(ReferenceGenome, :to_param => "1")
      ReferenceGenome.stub!(:new).and_return(@reference_genome)
    end
    
    describe "with successful save" do
  
      def do_post
        @reference_genome.should_receive(:save).and_return(true)
        post :create, :reference_genome => {}
      end
  
      it "should create a new reference_genome" do
        ReferenceGenome.should_receive(:new).with({}).and_return(@reference_genome)
        do_post
      end

      it "should redirect to the reference_genome index" do
        do_post
        response.should redirect_to(reference_genomes_url)
      end
      
    end
    
    describe "with failed save" do

      def do_post
        @reference_genome.should_receive(:save).and_return(false)
        post :create, :reference_genome => {}
      end
  
      it "should re-render 'new'" do
        do_post
        response.should render_template('new')
      end
      
    end
  end

  describe "handling PUT /reference_genomes/1" do

    before(:each) do
      @reference_genome = mock_model(ReferenceGenome, :to_param => "1")
      ReferenceGenome.stub!(:find).and_return(@reference_genome)
    end
    
    describe "with successful update" do

      def do_put
        @reference_genome.should_receive(:update_attributes).and_return(true)
        put :update, :id => "1"
      end

      it "should find the reference_genome requested" do
        ReferenceGenome.should_receive(:find).with("1").and_return(@reference_genome)
        do_put
      end

      it "should update the found reference_genome" do
        do_put
        assigns(:reference_genome).should equal(@reference_genome)
      end

      it "should assign the found reference_genome for the view" do
        do_put
        assigns(:reference_genome).should equal(@reference_genome)
      end

      it "should redirect to the reference_genome index" do
        do_put
        response.should redirect_to(reference_genomes_url)
      end

    end
    
    describe "with failed update" do

      def do_put
        @reference_genome.should_receive(:update_attributes).and_return(false)
        put :update, :id => "1"
      end

      it "should re-render 'edit'" do
        do_put
        response.should render_template('edit')
      end

    end
  end

  describe "handling DELETE /reference_genomes/1" do

    before(:each) do
      @reference_genome = mock_model(ReferenceGenome, :destroy => true)
      ReferenceGenome.stub!(:find).and_return(@reference_genome)
    end
  
    def do_delete
      delete :destroy, :id => "1"
    end

    it "should find the reference_genome requested" do
      ReferenceGenome.should_receive(:find).with("1").and_return(@reference_genome)
      do_delete
    end
  
    it "should call destroy on the found reference_genome" do
      @reference_genome.should_receive(:destroy)
      do_delete
    end
  
    it "should redirect to the reference_genomes list" do
      do_delete
      response.should redirect_to(reference_genomes_url)
    end
  end
end

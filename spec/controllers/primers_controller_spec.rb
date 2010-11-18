require 'spec_helper'

describe PrimersController do

  def mock_primer(stubs={})
    @mock_primer ||= mock_model(Primer, stubs)
  end

  describe "GET index" do
    it "assigns all primers as @primers" do
      Primer.stub(:find).with(:all).and_return([mock_primer])
      get :index
      assigns[:primers].should == [mock_primer]
    end
  end

  describe "GET show" do
    it "assigns the requested primer as @primer" do
      Primer.stub(:find).with("37").and_return(mock_primer)
      get :show, :id => "37"
      assigns[:primer].should equal(mock_primer)
    end
  end

  describe "GET new" do
    it "assigns a new primer as @primer" do
      Primer.stub(:new).and_return(mock_primer)
      get :new
      assigns[:primer].should equal(mock_primer)
    end
  end

  describe "GET edit" do
    it "assigns the requested primer as @primer" do
      Primer.stub(:find).with("37").and_return(mock_primer)
      get :edit, :id => "37"
      assigns[:primer].should equal(mock_primer)
    end
  end

  describe "POST create" do

    describe "with valid params" do
      it "assigns a newly created primer as @primer" do
        Primer.stub(:new).with({'these' => 'params'}).and_return(mock_primer(:save => true))
        post :create, :primer => {:these => 'params'}
        assigns[:primer].should equal(mock_primer)
      end

      it "redirects to the created primer" do
        Primer.stub(:new).and_return(mock_primer(:save => true))
        post :create, :primer => {}
        response.should redirect_to(primers_url)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved primer as @primer" do
        Primer.stub(:new).with({'these' => 'params'}).and_return(mock_primer(:save => false))
        post :create, :primer => {:these => 'params'}
        assigns[:primer].should equal(mock_primer)
      end

      it "re-renders the 'new' template" do
        Primer.stub(:new).and_return(mock_primer(:save => false))
        post :create, :primer => {}
        response.should render_template('new')
      end
    end

  end

  describe "PUT update" do

    describe "with valid params" do
      it "updates the requested primer" do
        Primer.should_receive(:find).with("37").and_return(mock_primer)
        mock_primer.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :primer => {:these => 'params'}
      end

      it "assigns the requested primer as @primer" do
        Primer.stub(:find).and_return(mock_primer(:update_attributes => true))
        put :update, :id => "1"
        assigns[:primer].should equal(mock_primer)
      end

      it "redirects to the primer" do
        Primer.stub(:find).and_return(mock_primer(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(primers_url)
      end
    end

    describe "with invalid params" do
      it "updates the requested primer" do
        Primer.should_receive(:find).with("37").and_return(mock_primer)
        mock_primer.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :primer => {:these => 'params'}
      end

      it "assigns the primer as @primer" do
        Primer.stub(:find).and_return(mock_primer(:update_attributes => false))
        put :update, :id => "1"
        assigns[:primer].should equal(mock_primer)
      end

      it "re-renders the 'edit' template" do
        Primer.stub(:find).and_return(mock_primer(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('edit')
      end
    end

  end

  describe "DELETE destroy" do
    it "destroys the requested primer" do
      Primer.should_receive(:find).with("37").and_return(mock_primer)
      mock_primer.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the primers list" do
      Primer.stub(:find).and_return(mock_primer(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(primers_url)
    end
  end

end

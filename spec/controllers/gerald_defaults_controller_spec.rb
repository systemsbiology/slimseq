require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe GeraldDefaultsController do
  include AuthenticatedSpecHelper

  before(:each) do
    login_as_staff
  end

  describe "handling POST /gerald_defaults/1/update" do

    before(:each) do
      @gerald_defaults = mock_model(GeraldDefaults, :to_param => "1")
      GeraldDefaults.should_receive(:find).with("1").and_return(@gerald_defaults)
      @sequencing_run = mock_model(SequencingRun, :id => 1)
      SequencingRun.should_receive(:find).with("2").and_return(@sequencing_run)
      @flow_cell = mock_model(FlowCell)
      @sequencing_run.should_receive(:flow_cell).and_return(@flow_cell)
      @flow_cell.should_receive(:flow_cell_lanes).and_return( mock("Array of lanes") )
    end
    
    describe "with successful update" do

      def do_put
        @gerald_defaults.should_receive(:update_attributes).and_return(true)
        put :update, :id => "1", :sequencing_run_id => "2"
      end

      it "should update the found gerald_defaults" do
        do_put
        assigns(:gerald_defaults).should equal(@gerald_defaults)
      end

      it "should assign the found gerald_defaults for the view" do
        do_put
        assigns(:gerald_defaults).should equal(@gerald_defaults)
      end

      it "should redirect to gerald_configurations/new" do
        do_put
        response.should redirect_to(new_sequencing_run_gerald_configuration_path(@sequencing_run))
      end

    end
    
    describe "with failed update" do

      def do_put
        @gerald_defaults.should_receive(:update_attributes).and_return(false)
        put :update, :id => "1", :sequencing_run_id => "2"
      end

      it "should re-render 'edit'" do
        do_put
        response.should render_template('gerald_configurations/new')
      end

    end
  end
end

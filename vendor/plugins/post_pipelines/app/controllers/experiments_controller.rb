class ExperimentsController < ApplicationController

  ########################################################################
  # display the page that launches a pipeline for this experiment:
  # next webhit goes to /post_pipeline/launch

  def pipeline
    @experiment=Experiment.find(params[:id])
    @samples=@experiment.samples
  end

end

class SampleSetsController < ApplicationController
  before_filter :load_dropdown_selections, :login_required
  
  def new
    if(params[:step] == "2")
      @sample_set = SampleSet.new(params[:sample_set])

      if(@sample_set.valid?)
        if(@sample_set.naming_scheme_id != nil)
          @naming_scheme = NamingScheme.find(@sample_set.naming_scheme_id)
          @naming_elements = @naming_scheme.ordered_naming_elements
        end

        @samples = Array.new
        params[:sample_set][:number_of_samples].to_i.times do
          sample = Sample.new(
            :submission_date => @sample_set.submission_date,
            :naming_scheme_id => @sample_set.naming_scheme_id,
            :sample_prep_kit_id => @sample_set.sample_prep_kit_id,
            :reference_genome_id => @sample_set.reference_genome_id,
            :desired_read_length => @sample_set.desired_read_length,
            :alignment_start_position => @sample_set.alignment_start_position,
            :alignment_end_position => @sample_set.alignment_end_position,
            :insert_size => @sample_set.insert_size,
            :budget_number => @sample_set.budget_number,
            :submitted_by_id => current_user.id,
            :sample_set => @sample_set
          )

          # default visibility and text per naming element for naming schemes
          sample.populate_default_visibilities_and_texts

          @samples << sample
        end        
      else
        # if the sample set info is invalid, kick back to step 1
        params[:step] = "1"
      end
    else
      @sample_set = SampleSet.new
    end
  end

  def create
#    @sample_set = SampleSet.new(params[:sample_set])
#    params[:sample].each_value { |sample| @sample_set.samples.build(sample) }
  end

private

  def load_dropdown_selections
    @lab_groups = current_user.accessible_lab_groups
    @naming_schemes = NamingScheme.find(:all, :order => "name ASC")
    @sample_prep_kits = SamplePrepKit.find(:all, :order => "name ASC")
    @reference_genomes = ReferenceGenome.find(:all, :order => "name ASC")
  end
end

class SamplesController < ApplicationController

  def pipeline
    @sample=Sample.find(params[:id])
    
    @disable_launch=false
    @why_disabled=''

    # Check for existing export_file (hey, it happens (see sample w/id=232)
    # fixme: Can't yet; at least not easily; have to check all fcl's

    # Check for valid prep kit:
    if @sample.sample_prep_kit.name!='mRNASeq'
      @disable_launch=true
      @why_disabled="Sample was not prepared with the mRNAseq prep kit (#{@sample.sample_prep_kit.name})"
    end

    # check for valid ref_genome
    if !@disable_launch
      begin
        @ref_genome_name=@sample.rna_seq_ref_genome.description
      rescue RuntimeError => err
        @ref_genome_name=err.message
        @disable_launch=true
        @why_disabled="No valid reference genome found"
      end
    end

    # get align parameters from config
    # NOT: for now, hard code
    aligner=@sample.post_pipeline_aligner
#    key="#{aligner}_opts".to_sym
#    rnaseq_conf=YAML.load_file('/local/apps/SLIMarray/rails/cap_slimarray_staging/slimseq_phonybone/vendor/plugins/post_pipeline/config/application.yml')
#    raise "#{rnaseq_conf.inspect}"
    #  fixme: until the rnaseq_pipeline config file acutally exists somewhere on slim, hardcode it for now
    @aligner_params='-k 11 -m 10 -t --best -q'

  end

end

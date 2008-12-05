class GeraldConfigurationsController < ApplicationController
  before_filter :get_sequencing_run
  
  def new
    @flow_cell_lanes = @sequencing_run.flow_cell.flow_cell_lanes
  end

  def create
    @lanes = params[:lanes]
    
    write_config_file
  end
  
  def download
    send_file "tmp/txt/#{@sequencing_run.run_name}-config.txt", :type => 'text/plain'
  end

private
  
  def get_sequencing_run
    # search by id if applicable
    if(params[:sequencing_run_id] != nil)
      @sequencing_run = SequencingRun.find(params[:sequencing_run_id])
    # otherwise search by name if applicable
    elsif(params[:sequencing_run_name] != nil)
      
    else
      raise "No sequencing run identifier provided"
    end    
  end

  def write_config_file
    @file_name = "tmp/txt/#{@sequencing_run.run_name}-config.txt"
    
    file = File.new(@file_name, "w")
    
    file << "ANALYSIS eland_extended\n"
    file << "SEQUENCE_FORMAT --fasta\n"
    file << "ELAND_MULTIPLE_INSTANCES 8\n"
    file << "QF_PARAMS '(NEIGHBOUR >=2.0) && (CHASTITY >= 0.6)'"
    @lanes.keys.sort.each do |i|
      hash = @lanes[i]
      file << "#{hash[:lane_number]}:ELAND_GENOME #{hash[:eland_genome]}\n"
      file << "#{hash[:lane_number]}:ELAND_SEED_LENGTH #{hash[:eland_seed_length]}\n"
      file << "#{hash[:lane_number]}:ELAND_MAX_MATCHES #{hash[:eland_max_matches]}\n"
      file << "#{hash[:lane_number]}:USE_BASES #{hash[:use_bases]}\n"
    end
    
    file.close
  end
end

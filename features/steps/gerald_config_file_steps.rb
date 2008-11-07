Given /I am on the new gerald_configurations page/i do
  sample_1 = create_sample
  sample_2 = create_sample
  flow_cell = create_flow_cell
  flow_cell_lane_1 = create_flow_cell_lane(:samples => [sample_1], :flow_cell => flow_cell)
  flow_cell_lane_2 = create_flow_cell_lane(:samples => [sample_2], :flow_cell => flow_cell)
  instrument = create_instrument
  sequencing_run = create_sequencing_run(:flow_cell => flow_cell, :instrument => instrument)
  visits "/sequencing_runs/#{sequencing_run.id}/gerald_configurations/new"
end

Then /I should see the following parameters:/ do |parameter_table|
  parameter_table.hashes.each do |hash|
    # make sure the body of the response contains each parameter somewhere
    response.body.should =~ /#{hash[:lane]}:ELAND_GENOME #{hash[:genome]}/m
    response.body.should =~ /#{hash[:lane]}:ELAND_SEED_LENGTH #{hash[:seed_length]}/m
    response.body.should =~ /#{hash[:lane]}:ELAND_MAX_MATCHES #{hash[:max_matches]}/m
    response.body.should =~ /#{hash[:lane]}:USE_BASES #{hash[:use_bases]}/m
  end
end
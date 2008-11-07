Given /I am on the new sequencing_run page/i do
  FlowCell.create!(:name => "Flow cell name", :date_generated => "2008-11-04",
    :status => "clustered")
  Instrument.create!(:name => "Super sequencer", :serial_number => "ABC1234")
  visits "/sequencing_runs/new"
end

Given /there are (\d+) sequencing_runs/i do |n|
  SequencingRun.transaction do
    SequencingRun.destroy_all
    
    instrument = Instrument.create!(:name => "Super sequencer", :serial_number => "ABC1234")
    n.to_i.times do |n|
      SequencingRun.create(
        :flow_cell => FlowCell.create(:name => "Flow cell #{n}",
          :date_generated => "2008-11-04", :status => "clustered"),
        :instrument => instrument
      )
    end
  end
end

When /I delete the first sequencing_run/i do
  visits sequencing_runs_url
  clicks_link "Destroy"
end

Then /there should be (\d+) sequencing_runs left/i do |n|
  SequencingRun.count.should == n.to_i
  response.should have_tag("table tr", n.to_i + 1) # There is a header row too
end

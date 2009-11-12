Given /I am on the samples page/ do
  project_chipseq = create_project(:name => "ChIP-Seq")
  project_rnaseq = create_project(:name => "RNA-Seq")
  visits "/samples"
end

When /I choose to browse by project and submitter/ do
  
end

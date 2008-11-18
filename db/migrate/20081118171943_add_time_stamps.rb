class AddTimeStamps < ActiveRecord::Migration
  def self.up
    add_timestamps :charges
    add_timestamps :charge_periods
    add_timestamps :charge_sets
    add_timestamps :charge_templates
    add_timestamps :flow_cells
    add_timestamps :flow_cell_lanes
    add_timestamps :instruments
    add_timestamps :lab_groups
    add_timestamps :lab_memberships
    add_timestamps :naming_elements
    add_timestamps :naming_schemes
    add_timestamps :naming_terms
    add_timestamps :organisms
    add_timestamps :projects
    add_timestamps :reference_genomes
    add_timestamps :samples
    add_timestamps :sample_prep_kits
    add_timestamps :sample_terms
    add_timestamps :sample_texts
    add_timestamps :sequencing_runs
    add_timestamps :site_config
  end

  def self.down
    remove_timestamps :charges
    remove_timestamps :charge_periods
    remove_timestamps :charge_sets
    remove_timestamps :charge_templates
    remove_timestamps :flow_cells
    remove_timestamps :flow_cell_lanes
    remove_timestamps :instruments
    remove_timestamps :lab_groups
    remove_timestamps :lab_memberships
    remove_timestamps :naming_elements
    remove_timestamps :naming_schemes
    remove_timestamps :naming_terms
    remove_timestamps :organisms
    remove_timestamps :projects
    remove_timestamps :reference_genomes
    remove_timestamps :samples
    remove_timestamps :sample_prep_kits
    remove_timestamps :sample_terms
    remove_timestamps :sample_texts
    remove_timestamps :sequencing_runs
    remove_timestamps :site_config
  end
end

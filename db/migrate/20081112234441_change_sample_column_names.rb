class ChangeSampleColumnNames < ActiveRecord::Migration
  def self.up
    rename_column :samples, :short_sample_name, :name_on_tube
    rename_column :samples, :sample_name, :sample_description
    rename_column :naming_elements, :include_in_sample_name,
                  :include_in_sample_description
  end

  def self.down
    rename_column :samples, :name_on_tube, :short_sample_name
    rename_column :samples, :sample_description, :sample_name
    rename_column :naming_elements, :include_in_sample_description,
                  :include_in_sample_name
  end
end

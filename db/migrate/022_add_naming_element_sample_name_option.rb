class AddNamingElementSampleNameOption < ActiveRecord::Migration
  def self.up
    add_column :naming_elements, :include_in_sample_name, :boolean,
               :default => true
  end

  def self.down
    remove_column :naming_elements, :include_in_sample_name
  end
end

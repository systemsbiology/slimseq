class CreatePlatforms < ActiveRecord::Migration
  def self.up
    create_table :platforms do |t|
      t.string :name
      t.string :samples_per_flow_cell
      t.string :loading_location_name
      t.boolean :uses_gerald
      t.boolean :requires_concentrations

      t.timestamps
    end

    Platform.create(:name => "Illumina",
                    :samples_per_flow_cell => "8",
                    :loading_location_name => "lane",
                    :uses_gerald => true,
                    :requires_concentrations => true)
  end

  def self.down
    drop_table :platforms
  end
end

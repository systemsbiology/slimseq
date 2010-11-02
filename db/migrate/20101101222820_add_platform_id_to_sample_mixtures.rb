class AddPlatformIdToSampleMixtures < ActiveRecord::Migration
  def self.up
    add_column :sample_mixtures, :platform_id, :integer

    platform = Platform.first
    SampleMixture.all.each{|m| m.update_attribute('platform_id', platform.id)}
  end

  def self.down
    remove_column :sample_mixtures, :platform_id
  end
end

class AddPlatformIdToSamplePrepKits < ActiveRecord::Migration
  def self.up
    add_column :sample_prep_kits, :platform_id, :integer

    platform = Platform.first
    SamplePrepKit.all.each{|k| k.update_attribute('platform_id', platform.id)}
  end

  def self.down
    remove_column :sample_prep_kits, :platform_id
  end
end

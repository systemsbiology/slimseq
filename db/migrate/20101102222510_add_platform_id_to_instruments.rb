class AddPlatformIdToInstruments < ActiveRecord::Migration
  def self.up
    add_column :instruments, :platform_id, :integer

    platform = Platform.first
    Instrument.all.each do |instrument|
      instrument.update_attributes(:platform_id => platform)
    end
  end

  def self.down
    remove_column :instruments, :platform_id
  end
end

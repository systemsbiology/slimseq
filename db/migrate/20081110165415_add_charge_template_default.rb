class AddChargeTemplateDefault < ActiveRecord::Migration
  def self.up
    add_column :charge_templates, :default, :boolean
  end

  def self.down
    remove_column :charge_templates, :default
  end
end

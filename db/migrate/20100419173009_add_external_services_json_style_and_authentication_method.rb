class AddExternalServicesJsonStyleAndAuthenticationMethod < ActiveRecord::Migration
  def self.up
    add_column :external_services, :json_style, :string
    add_column :external_services, :authentication_method, :string
  end

  def self.down
    remove_column :external_services, :json_style
    remove_column :external_services, :authentication_method
  end
end

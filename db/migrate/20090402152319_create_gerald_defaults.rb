class CreateGeraldDefaults < ActiveRecord::Migration
  def self.up
    create_table :gerald_defaults do |t|
      t.string :email_list, :default => "admin@example.com"
      t.string :email_server, :default => "mail.example.com:25"
      t.string :email_domain, :default => "example.com"
      t.integer :eland_seed_length, :default => 25
      t.integer :eland_max_matches, :default => 15
      t.string :header, :default => "ANALYSIS eland_extended"
    end

    GeraldDefaults.create
  end

  def self.down
    drop_table :gerald_defaults
  end
end

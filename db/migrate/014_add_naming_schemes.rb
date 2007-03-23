class AddNamingSchemes < ActiveRecord::Migration
  def self.up
    # the naming schemes
    create_table "naming_schemes", :force => true do |t|
      t.column "name", :string, :limit => 100
      t.column "lock_version", :integer, :default => 0
    end
    
    # individual elements of a naming scheme
    create_table "naming_elements", :force => true do |t|
      t.column "name", :string, :limit => 100
      t.column "element_order", :integer
      t.column "group_element", :boolean
      t.column "optional", :boolean
      t.column "dependent_element_id", :integer
      t.column "naming_scheme_id", :integer
      t.column "lock_version", :integer, :default => 0
    end

    # vocabulary for the naming scheme elements
    create_table "naming_terms", :force => true do |t|
      t.column "term", :string, :limit => 100
      t.column "abbreviated_term", :string, :limit => 20
      t.column "naming_element_id", :integer
      t.column "lock_version", :integer, :default => 0
    end

    # terms associated with actual samples
    create_table "sample_terms", :force => true do |t|
      t.column "term_order", :integer
      t.column "sample_id", :integer
      t.column "naming_term_id", :integer
    end

    # users have a chosen naming scheme
    add_column :users, :current_naming_scheme_id, :integer
    
    # associate each sample with a naming scheme
    add_column :samples, :naming_scheme_id, :integer
  end

  def self.down
    remove_column :users, :current_naming_scheme_id
    remove_column :samples, :naming_scheme_id

    drop_table :naming_terms
    drop_table :naming_elements
    drop_table :naming_schemes
    drop_table :sample_terms
  end
end

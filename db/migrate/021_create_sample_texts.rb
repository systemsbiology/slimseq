class CreateSampleTexts < ActiveRecord::Migration
  def self.up
    # sample-specific free text
    create_table "sample_texts", :force => true do |t|
      t.column "text", :string
      t.column "lock_version", :integer, :default => 0
      t.column "sample_id", :integer
      t.column "naming_element_id", :integer
    end
  end

  def self.down
    drop_table :sample_texts
  end
end

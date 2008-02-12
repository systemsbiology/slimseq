class AddFreeTextNamingElement < ActiveRecord::Migration
  def self.up
    add_column :naming_elements, :free_text, :boolean
    
    # set all existing naming elements as non-free-text
    NamingElement.find(:all).each do |e|
      e.update_attribute('free_text', false)
    end
  end

  def self.down
    remove_column :naming_elements, :free_text, :boolean
  end
end

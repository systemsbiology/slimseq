class AddNamingTermOrder < ActiveRecord::Migration
  def self.up
    add_column :naming_terms, :term_order, :integer
    
    # provide order numbers for existing terms that match how they're coming up
    # right now, which is sorted by id
    naming_elements = NamingElement.find(:all)
    naming_elements.each do |e|
      naming_terms = e.naming_terms.find(:all, :order => "id ASC")
      current_order = 0
      naming_terms.each do |t|
        t.update_attribute('term_order', current_order)
        current_order += 1
      end
    end
  end

  def self.down
    remove_column :naming_terms, :term_order
  end
end

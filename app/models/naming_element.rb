class NamingElement < ActiveRecord::Base
  belongs_to :naming_scheme

  has_many :naming_terms, :dependent => :destroy

  def destroy_warning
    naming_terms = NamingTerm.find(:all, :conditions => ["naming_element_id = ?", id])
    
    return "Destroying this naming element will also destroy:\n" + 
           naming_terms.size.to_s + " naming term(s)\n" +
           "Are you sure you want to destroy it?"
  end

  def ordered_naming_terms
    return NamingTerm.find(:all, :conditions => ["naming_element_id = ?", self.id], :order => "term_order ASC")
  end
end
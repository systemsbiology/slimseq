class NamingScheme < ActiveRecord::Base
  has_many :naming_elements, :dependent => :destroy
  has_many :samples, :dependent => :destroy
  has_many :sample_sets
  
  validates_presence_of :name
  validates_uniqueness_of :name

  def destroy_warning
    samples = Sample.find(:all, :conditions => ["naming_scheme_id = ?", id])
    naming_elements = NamingElement.find(:all, :conditions => ["naming_scheme_id = ?", id])
    
    return "Destroying this naming scheme will also destroy:\n" + 
           samples.size.to_s + " sample(s)\n" +
           naming_elements.size.to_s + " naming element(s)\n" +
           "Are you sure you want to destroy it?"
  end

  def ordered_naming_elements
    return NamingElement.find(:all, :conditions => { :naming_scheme_id => id },
                                            :order => "element_order ASC" )
  end
  
  def default_visibilities
    visibility = Array.new
    
    for element in ordered_naming_elements
      if( element.dependent_element_id > 0 )
        visibility << false
      else
        visibility << true
      end
    end
    
    return visibility
  end
  
  def default_texts
    text_values = Hash.new

    for element in ordered_naming_elements
      # free text
      if( element.free_text )
        text_values[element.name] = ""
      end
    end
    
    return text_values
  end
end
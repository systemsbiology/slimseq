class NamingScheme < ActiveRecord::Base
  require 'csv'
  
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
      if( element.dependent_element_id != nil && element.dependent_element_id > 0 )
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

  def visibilities_from_params(schemed_params)
    visibility = Array.new
    
    for element in ordered_naming_elements
      if( schemed_params[element.name] == nil )
        visibility << false
      else
        visibility << true
      end
    end
    
    return visibility
  end
  
  def texts_from_params(schemed_params)
    text_values = Hash.new

    for element in ordered_naming_elements
      # free text
      if( element.free_text )
        if(schemed_params[element.name] == nil)
          text_values[element.name] = ""
        else
          text_values[element.name] = schemed_params[element.name]
        end
      end
    end
    
    return text_values
  end

  def element_selections_from_params(schemed_params)
    selections = Array.new
    
    for n in 0..ordered_naming_elements.size-1
      element = ordered_naming_elements[n]
      if( !element.free_text )
        if( schemed_params[element.name] == nil )
          selections[n] = nil
        else
          selections[n] = schemed_params[element.name]
        end
      end
    end
    
    return selections
  end
  
  def generate_sample_description(schemed_params)
    name = ""
    
    for element in ordered_naming_elements
      depends_upon_element_with_no_selection = false
      depends_upon_element = element.depends_upon_element
      if(depends_upon_element != nil && schemed_params[depends_upon_element.name].to_i <= 0)
        depends_upon_element_with_no_selection = true
      end

      # put an underscore between terms
      if(name.length > 0)
        name += "_"
      end
      
      if( schemed_params[element.name] != nil && !depends_upon_element_with_no_selection )
        # free text
        if( element.free_text )
          name += schemed_params[element.name]
        elsif( schemed_params[element.name].to_i > 0 )
          name += NamingTerm.find(schemed_params[element.name]).abbreviated_term
        end
      end
    end
    
    return name
  end
  
  def visibilities_from_terms(sample_terms)
    # get default visibilities
    visibility = default_visibilities
    
    # modify visibilities based on actual selections
    for term in sample_terms
      # see if there's a naming term for this element,
      # and if so show it
      i = ordered_naming_elements.index( term.naming_term.naming_element )
      if( i != nil)
        visibility[i] = true
      end        
    end

    # find dependent elements, and show them
    # if the element they depend upon is shown
    for i in (0..ordered_naming_elements.size-1)
      element = ordered_naming_elements[i]

      # does this element depend upon another?
      if( element.dependent_element_id != nil && element.dependent_element_id > 0 )
        dependent_element = NamingElement.find(element.dependent_element_id)
        # check each term to see if the dependent is used
        for term in sample_terms
          if(term.naming_term.naming_element == dependent_element)
            visibility[i] = true
          end
        end
      end
    end
    
    return visibility
  end
  
  def texts_from_terms(sample_texts)
    text_values = Hash.new
    # set sample texts
    for text in sample_texts
      text_values[text.naming_element.name] = text.text
    end
    
    return text_values
  end
  
  def element_selections_from_terms(sample_terms)
    selections = Array.new(ordered_naming_elements.size, -1)
    
    for term in sample_terms
      # see if there's a naming term for this element,
      # and if so record selection
      naming_term = term.naming_term
      i = ordered_naming_elements.index( naming_term.naming_element )
      if( i != nil)
        selections[i] = naming_term.id
      end
    end
    
    return selections
  end
  
  def summary_hash
    return {
      :id => id,
      :name => name,
      :updated_at => updated_at,
      :uri => "#{SiteConfig.site_url}/naming_schemes/#{id}"
    }
  end
  
  def detail_hash
    naming_element_array = Array.new
    naming_elements.find(:all, :order => "element_order ASC").each do |ne|
      naming_term_array = Array.new
      ne.naming_terms.find(:all, :order => "term_order ASC").each do |nt|
        naming_term_array << nt.term
      end
      
      naming_element_array << {
        :name => ne.name,
        :group_element => ne.group_element,
        :optional => ne.optional,
        :free_text => ne.free_text,
        :depends_on => ne.depends_upon_element,
        :naming_terms => naming_term_array
      }
    end
    
    return {
      :id => id,
      :name => name,
      :updated_at => updated_at,
      :naming_elements => naming_element_array
    }
  end
  
  def to_csv
    csv_file_name = "#{RAILS_ROOT}/tmp/csv/#{SiteConfig.site_name}_naming_scheme_" +
      "#{name}-#{Date.today.to_s}.csv"
    
    csv_file = File.open(csv_file_name, 'wb')
    CSV::Writer.generate(csv_file) do |csv|
      naming_elements.each do |ne|
        if(ne.free_text == true)
          csv << [ne.name, "FREE TEXT"]
        else
          csv << [ne.name] + ne.naming_terms.collect {|nt| nt.term}
        end
      end
    end
    
    csv_file.close
  end
end
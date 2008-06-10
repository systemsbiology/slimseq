class NamingElement < ActiveRecord::Base
  belongs_to :naming_scheme

  has_many :naming_terms, :dependent => :destroy
  has_many :sample_texts, :dependent => :destroy
  
  belongs_to :depends_upon_element, :foreign_key => 'dependent_element_id',
             :class_name => 'NamingElement'
  
  has_many :dependent_elements, :foreign_key => 'dependent_element_id',
             :class_name => 'NamingElement'
  
  def destroy_warning
    naming_terms = NamingTerm.find(:all, :conditions => ["naming_element_id = ?", id])
    sample_texts = SampleText.find(:all, :conditions => ["naming_element_id = ?", id])
    
    return "Destroying this naming element will also destroy:\n" + 
           naming_terms.size.to_s + " naming term(s)\n" +
           sample_texts.size.to_s + " sample text(s)\n" +
           "Are you sure you want to destroy it?"
  end

  def ordered_naming_terms
    return NamingTerm.find(:all, :conditions => ["naming_element_id = ?", self.id], :order => "term_order ASC")
  end

  def free_text_conversion
    # conversion TO free text
    if( free_text == true )
      sample_terms = Array.new
      naming_terms.each do |nt|
        sample_terms.concat(nt.sample_terms)
      end
      
      # create sample texts for each of the sample terms, and then destroy
      # the sample terms
      sample_terms.each do |st|
        SampleText.create(:naming_element_id => id,
          :sample_id => st.sample_id,
          :text => st.naming_term.term
        )
        
        st.destroy
      end
      
      # destroy the naming terms
      naming_terms.each do |nt|
        nt.destroy
      end
      # conversion FROM free text
    else
      # create a naming term per each unique sample text
      term_order_counter = 0
      sample_texts.each do |st|
        if( NamingTerm.find(:all, :conditions => {
                :naming_element_id => id,
                :term => st.text,
                :abbreviated_term => st.text }).size == 0 )
          NamingTerm.create(
            :naming_element_id => id,
            :term => st.text,
            :abbreviated_term => st.text,
            :term_order => term_order_counter)
          term_order_counter += 1
        end
      end
      
      # create a sample term per each sample text
      term_order_counter = 0
      sample_texts.each do |st|
        nt = NamingTerm.find(:first, :conditions => {
                :naming_element_id => id,
                :term => st.text,
                :abbreviated_term => st.text })
        
        SampleTerm.create(
          :naming_term_id => nt.id,
          :sample_id => st.sample_id,
          :term_order => term_order_counter
          )
        term_order_counter += 1
      end
      
      # destroy the sample texts
      sample_texts.each do |st|
        st.destroy
      end
    end
  end
end
class NamingElement < ActiveRecord::Base
  belongs_to :naming_scheme

  has_many :naming_terms, :dependent => :destroy

#  attr_accessor :selection, :hidden

#  def after_find
#    # elements with a dependency start as hidden
#    if dependent_element_id > 0
#      @hidden = true
#    end
#  end
end
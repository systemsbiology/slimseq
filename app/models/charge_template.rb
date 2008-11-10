class ChargeTemplate < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name

  validates_numericality_of :cost
  
  def self.default
    return ChargeTemplate.find(:first, :conditions => {:default => true})
  end
  
  def after_save
    # if this charge template is the default, make sure no other ones are
    if(default == true)
      templates = ChargeTemplate.find(:all, :conditions => ["id NOT IN (?)", id])
      templates.each do |t|
        t.update_attribute('default', false)
      end
    end
  end
end

class ChargePeriod < ActiveRecord::Base
  has_many :charge_sets, :dependent => :destroy
  
  validates_uniqueness_of :name

  def destroy_warning
    charge_sets = ChargeSet.find(:all, :conditions => ["charge_period_id = ?", id])
    
    return "Destroying this charge period will also destroy:\n" + 
           charge_sets.size.to_s + " charge set(s)\n" +
           "Are you sure you want to destroy it?"
  end

end

class ChargeSet < ActiveRecord::Base
  belongs_to :charge_period
  belongs_to :lab_group
  
  has_many :charges, :dependent => :destroy
  
  def get_totals
    totals = Hash.new(0)
    charges = Charge.find(:all, :conditions => ["charge_set_id = ?", id])
    for charge in charges
      totals['cost'] += charge.cost
    end
    
    totals['total_cost'] = totals['cost']
    
    return totals
  end

  def destroy_warning
    charges = Charge.find(:all, :conditions => ["charge_set_id = ?", id])
    
    return "Destroying this charge set will also destroy:\n" + 
           charges.size.to_s + " charge(s)\n" +
           "Are you sure you want to destroy it?"
  end

end

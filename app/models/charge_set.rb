class ChargeSet < ActiveRecord::Base
  belongs_to :charge_period
  has_many :charges, :dependent => :destroy
  
  def get_totals
    totals = Hash.new(0)
    charges = Charge.find(:all, :conditions => ["charge_set_id = ?", id])
    for charge in charges
      totals['chips'] += charge.chips_used
      totals['chip_cost'] += charge.chip_cost
      totals['labeling_cost'] += charge.labeling_cost
      totals['hybridization_cost'] += charge.hybridization_cost
      totals['qc_cost'] += charge.qc_cost
      totals['other_cost'] += charge.other_cost
    end
    
    totals['total_cost'] = totals['chip_cost'] + totals['labeling_cost'] +
                         totals['hybridization_cost'] + totals['qc_cost'] +
                         totals['other_cost']
    return totals
  end

  def destroy_warning
    charges = Charge.find(:all, :conditions => ["charge_set_id = ?", id])
    
    return "Destroying this charge set will also destroy:\n" + 
           charges.size.to_s + " charge(s)\n" +
           "Are you sure you want to destroy it?"
  end

end

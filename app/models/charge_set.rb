class ChargeSet < ActiveRecord::Base
  belongs_to :charge_period
  belongs_to :lab_group
  
  has_many :charges, :dependent => :destroy
  
  def total_cost
    total = 0
    charges = Charge.find(:all, :conditions => ["charge_set_id = ?", id])
    for charge in charges
      total += charge.cost
    end
    
    return total
  end

  def destroy_warning
    charges = Charge.find(:all, :conditions => ["charge_set_id = ?", id])
    
    return "Destroying this charge set will also destroy:\n" + 
           charges.size.to_s + " charge(s)\n" +
           "Are you sure you want to destroy it?"
  end

  def self.find_or_create_for_latest_charge_period(project, budget)
    # create a charge period if none exists
    if(ChargePeriod.count == 0)
      ChargePeriod.create(:name => "Default Charge Period")
    end
    
    set = ChargeSet.find(:first, :conditions => {
        :charge_period_id => ChargePeriod.latest.id,
        :lab_group_id => project.lab_group_id,
        :budget => budget
      })

    # create a new set only if an existing one isn't found
    if(set.nil?)
      set = ChargeSet.create(
        :charge_period_id => ChargePeriod.latest.id,
        :lab_group_id => project.lab_group_id,
        :budget => budget,
        :name => project.name
      )
    end
    
    return set
  end
end

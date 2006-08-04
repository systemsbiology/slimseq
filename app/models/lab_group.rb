class LabGroup < ActiveRecord::Base
  has_many :lab_memberships, :dependent => :destroy
  has_many :users, :through => :lab_memberships

  has_many :chip_transactions, :dependent => :destroy
  has_many :charge_sets, :dependent => :destroy
  has_many :samples, :dependent => :destroy
  has_many :inventory_checks, :dependent => :destroy

  validates_length_of :name, :within => 1..20
  validates_uniqueness_of :name

  def destroy_warning
    charge_sets = ChargeSet.find(:all, :conditions => ["lab_group_id = ?", id])
    samples = Sample.find(:all, :conditions => ["lab_group_id = ?", id])
    inventory_checks = InventoryCheck.find(:all, :conditions => ["lab_group_id = ?", id])
    chip_transactions = ChipTransaction.find(:all, :conditions => ["lab_group_id = ?", id])
    
    return "Destroying this lab group will also destroy:\n" + 
           charge_sets.size.to_s + " charge set(s)\n" +
           samples.size.to_s + " sample(s)\n" +
           inventory_checks.size.to_s + " inventory check(s)\n" +
           chip_transactions.size.to_s + " chip transaction(s)\n" +
           "Are you sure you want to destroy it?"
  end
end

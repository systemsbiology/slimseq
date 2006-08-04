class ChipType < ActiveRecord::Base
  belongs_to :organism
  has_many :chip_transactions, :dependent => :destroy
  has_many :samples, :dependent => :destroy
  has_many :inventory_checks, :dependent => :destroy
  
  validates_uniqueness_of :name
  validates_uniqueness_of :short_name
  validates_length_of :name, :within => 1..20
  validates_length_of :short_name, :within => 1..20

  def destroy_warning
    samples = Sample.find(:all, :conditions => ["lab_group_id = ?", id])
    inventory_checks = InventoryCheck.find(:all, :conditions => ["lab_group_id = ?", id])
    chip_transactions = ChipTransaction.find(:all, :conditions => ["lab_group_id = ?", id])
    
    return "Destroying this chip type will also destroy:\n" + 
           samples.size.to_s + " sample(s)\n" +
           inventory_checks.size.to_s + " inventory check(s)\n" +
           chip_transactions.size.to_s + " chip transaction(s)\n" +
           "Are you sure you want to destroy it?"
  end
end

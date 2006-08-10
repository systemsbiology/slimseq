class ChipTransaction < ActiveRecord::Base
  belongs_to :lab_group
  belongs_to :chip_type
  
  validates_associated :lab_group, :chip_type
  validates_presence_of :description
  validates_format_of :acquired_before_type_cast, :with => /^[0-9]*$/, :message=>"Must be a whole number"
  validates_format_of :used_before_type_cast, :with => /^[0-9]*$/, :message=>"Must be a whole number"
  validates_format_of :traded_sold_before_type_cast, :with => /^[0-9]*$/, :message=>"Must be a whole number"
  validates_format_of :borrowed_in_before_type_cast, :with => /^[0-9]*$/, :message=>"Must be a whole number"
  validates_format_of :returned_out_before_type_cast, :with => /^[0-9]*$/, :message=>"Must be a whole number"
  validates_format_of :borrowed_out_before_type_cast, :with => /^[0-9]*$/, :message=>"Must be a whole number"
  validates_format_of :returned_in_before_type_cast, :with => /^[0-9]*$/, :message=>"Must be a whole number"
  validates_length_of :description, :maximum=>250 

  def self.has_transactions?(group_id, type_id)
    if(find_all_in_lab_group_chip_type(group_id, type_id).size > 0)
      return true
    else
      return false
    end
  end

  def self.find_all_in_lab_group_chip_type(group_id, type_id)
    find(
          :all, 
          :conditions => ["lab_group_id = :lab_group_id AND chip_type_id = :chip_type_id",
                          { :lab_group_id => group_id, :chip_type_id => type_id } ],
          :order => "date DESC")
  end

  def self.get_chip_totals(chip_transactions)
    @totals = Hash.new(0)
    for transaction in chip_transactions
      if transaction.acquired != nil
        @totals['acquired'] += transaction.acquired
        @totals['chips'] += transaction.acquired
      end
      if transaction.used != nil
        @totals['used'] += transaction.used
        @totals['chips'] -= transaction.used
      end
      if transaction.traded_sold != nil
        @totals['traded_sold'] += transaction.traded_sold
        @totals['chips'] -= transaction.traded_sold
      end
      if transaction.borrowed_in != nil
        @totals['borrowed_in'] += transaction.borrowed_in
        @totals['chips'] += transaction.borrowed_in
      end
      if transaction.returned_out != nil
        @totals['returned_out'] += transaction.returned_out
        @totals['chips'] -= transaction.returned_out
      end
      if transaction.borrowed_out != nil
        @totals['borrowed_out'] += transaction.borrowed_out
        @totals['chips'] -= transaction.borrowed_out
      end
      if transaction.returned_in != nil
        @totals['returned_in'] += transaction.returned_in
        @totals['chips'] += transaction.returned_in
      end
    end
    
    return @totals
  end

end

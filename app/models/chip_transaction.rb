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

  def self.find_all_in_lab_group_chip_type(group_id, type_id)
    find(
          :all, 
          :conditions => ["lab_group_id = :lab_group_id AND chip_type_id = :chip_type_id",
                          { :lab_group_id => group_id, :chip_type_id => type_id } ],
          :order => "date DESC")
  end

end

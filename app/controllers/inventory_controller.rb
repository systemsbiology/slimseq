class InventoryController < ApplicationController

  def index
    # Administrators can see all lab groups, otherwise users
    # are restricted to seeing only lab groups they belong to
    if(current_user.admin?)
      @lab_groups = LabGroup.find(:all, :order => "name ASC")
    else
      @lab_groups = current_user.lab_groups
    end
    @chip_types = ChipType.find(:all, :order => "name ASC")
  end

end

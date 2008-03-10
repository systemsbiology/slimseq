# Copyright (c) 2005 James Adam
#
# This is the MIT license, the license Ruby on Rails itself is licensed 
# under.
#
# Permission is hereby granted, free of charge, to any person obtaining 
# a copy of this software and associated documentation files (the 
# "Software"), to deal in the Software without restriction, including 
# without limitation the rights to use, copy, modify, merge, publish, 
# distribute, sublicense, and/or sell copies of the Software, and to permit
# persons to whom the Software is furnished to do so, subject to the 
# following conditions:
#
# The above copyright notice and this permission notice shall be included 
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# A User class which includes functionality from the LoginEngine::AuthenticatedUser
# module, and is further extended by UserEngine::AuthorizedUser.

class User < ActiveRecord::Base
  include LoginEngine::AuthenticatedUser
  include UserEngine::AuthorizedUser

  has_many :lab_memberships, :dependent => :destroy
  has_many :lab_groups, :through => :lab_memberships
  belongs_to :naming_scheme, :foreign_key => "current_naming_scheme_id"

  # Returns the full name of this user.
  def fullname
    "#{self.firstname} #{self.lastname}"
  end
  
  # Returns true if the user belongs to the Role "Facility"
  def staff?
    self.roles.include?(Role.find(:first, :conditions => ["name = ?", "Staff"]))
  end
  
  # Returns an Array of the ids of quality traces the user has access to
  def get_lab_group_ids
    # Administrators and staff can see all bioanalyzer runs, customers
    # are restricted to seeing bioanalyzer runs for lab groups they belong to
    if(self.staff? || self.admin?)
      @lab_groups = LabGroup.find(:all, :order => "name ASC")
    else
      @lab_groups = self.lab_groups
    end
    
    # gather ids of user's lab groups
    lab_group_ids = Array.new
    for lab_group in @lab_groups
      lab_group_ids << lab_group.id
    end
    lab_group_ids.flatten
    
    return lab_group_ids
  end
end
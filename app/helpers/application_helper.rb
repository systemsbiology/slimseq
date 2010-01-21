# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def fmt_dollars(amt)
    sprintf("$%0.2f", amt)
  end

  def charge_set_options_for_select(selected_value = nil)
    charge_set_choices = Array.new

    charge_periods = ChargePeriod.find(:all, :order => "name DESC")
    for period in charge_periods
      charge_sets = ChargeSet.find(:all, :conditions => ["charge_period_id = ?", period.id],
                                   :order => "name ASC")
      for set in charge_sets
        charge_set_choices << [period.name + " - " + set.name, set.id]
      end
    end

    options_for_select(charge_set_choices, selected = selected_value)
  end
  
  def link_if_staff_or_admin(name, options = {}, html_options = {}, *params, &block)
    if current_user.staff_or_admin?
      wrap_tag = html_options.delete(:wrap_in)
      result = link_to(name, options, html_options, *params)
      
      result = content_tag(wrap_tag, result, html_options) if wrap_tag != nil
      
      return result
    else
      return ""
    end
  end
  
  def staff_or_admin?
    current_user.staff_or_admin?
  end

  def link_to_obj(obj)
    link_to (obj.name || "some #{obj.class}"),obj
  end
end

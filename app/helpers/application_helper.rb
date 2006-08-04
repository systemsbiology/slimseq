# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include LoginEngine
  include UserEngine

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
end

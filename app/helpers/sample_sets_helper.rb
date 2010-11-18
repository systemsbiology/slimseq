module SampleSetsHelper
  require 'ostruct'
  
  def sample_prep_kit_choices(platform)
    choices = SamplePrepKit.not_custom.for_platform(platform)
    
    # hack to add the custom option to the end of the array
    custom_choice = Struct.new(:id, :name).new("-1","Custom Prep")
    choices += [custom_choice]

    return choices
  end

  def primer_choices(platform)
    choices = Primer.not_custom.for_platform(platform)
    
    # hack to add the custom option to the end of the array
    custom_choice = Struct.new(:id, :name).new("-1","Custom Primer")
    choices += [custom_choice]

    return choices
  end
end

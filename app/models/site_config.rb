class SiteConfig < ActiveRecord::Base
  set_table_name "site_config"

  def SiteConfig.track_inventory?
    return SiteConfig.find(1).track_inventory
  end
  
  def SiteConfig.track_hybridizations?
    return SiteConfig.find(1).track_hybridizations
  end

  def SiteConfig.track_charges?
    return SiteConfig.find(1).track_charges
  end
  
  def SiteConfig.using_affy_arrays?
    if SiteConfig.find(1).array_platform == "affy" ||
       SiteConfig.find(1).array_platform == "both"
      return true
    end
  end
  
  def SiteConfig.multi_platform?
    if SiteConfig.find(1).array_platform == "both"
      return true
    end 
  end
  
  def SiteConfig.create_gcos_files?
    return SiteConfig.find(1).create_gcos_files
  end
  
  def SiteConfig.using_sbeams?
    return SiteConfig.find(1).using_sbeams
  end
  
  def SiteConfig.organization_name
    return SiteConfig.find(1).organization_name
  end

  def SiteConfig.facility_name
    return SiteConfig.find(1).facility_name
  end
  
  def SiteConfig.array_platform
    return SiteConfig.find(1).array_platform
  end
  
  def SiteConfig.gcos_output_path
    return SiteConfig.find(1).gcos_output_path
  end
  
  def SiteConfig.use_LDAP?
    return SiteConfig.find(1).use_LDAP
  end

  def SiteConfig.LDAP_server
    return SiteConfig.find(1).LDAP_server
  end
  
  def SiteConfig.LDAP_DN
    return SiteConfig.find(1).LDAP_DN
  end
end

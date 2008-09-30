class SiteConfig < ActiveRecord::Base
  set_table_name "site_config"

  def SiteConfig.track_charges?
    return SiteConfig.find(1).track_charges
  end
  
  def SiteConfig.site_name
    return SiteConfig.find(1).site_name
  end
  
  def SiteConfig.organization_name
    return SiteConfig.find(1).organization_name
  end

  def SiteConfig.facility_name
    return SiteConfig.find(1).facility_name
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

  def SiteConfig.administrator_email
    if(SiteConfig.table_exists?)
      return SiteConfig.find(1).administrator_email
    end
  end
  
  def SiteConfig.raw_data_root_path
    return SiteConfig.find(1).raw_data_root_path  
  end
  
  def SiteConfig.site_url
    return SiteConfig.find(1).site_url
  end
end

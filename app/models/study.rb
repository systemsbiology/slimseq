class Study < ActiveRecord::Base
  has_many :experiments
  belongs_to :project

  def tree_hash 
    children=experiments.map {|e| e.tree_hash}
    { :id => "st_#{id}",
      :text => name,
      :href => "#{SiteConfig.site_url}/studies/edit/#{id}",
      :children=>children }
  end

end

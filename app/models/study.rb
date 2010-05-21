class Study < ActiveRecord::Base
  has_many :experiments
  belongs_to :project

  def tree_hash 
    site_url=ENV['RAILS_RELATIVE_URL_ROOT']
    children=experiments.map {|e| e.tree_hash}
    { :id => "st_#{id}",
      :text => name,
      :href => "#{site_url}/studies/edit/#{id}",
      :children=>children }
  end

end

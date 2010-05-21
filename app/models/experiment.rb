class Experiment < ActiveRecord::Base
  has_many :samples
  belongs_to :study

  def tree_hash 
    site_url=ENV['RAILS_RELATIVE_URL_ROOT']
    children=samples.map {|s| s.tree_hash}
    { :id => "e_#{id}",
      :text => name,
      :href => "#{site_url}/experiments/edit/#{id}",
      :children=>children }
  end
end

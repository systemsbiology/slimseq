class MultiplexCode < ActiveRecord::Base
  belongs_to :multiplexing_scheme

  has_many :samples
end

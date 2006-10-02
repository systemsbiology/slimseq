class AddSamples < ActiveRecord::Base
  def self.columns() @columns ||= []; end
  def self.column(name, sql_type = nil, default = nil, null = true)
    columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
  end

  column :submission_date, :date
  column :number, :integer
  column :lab_group_id, :integer
  column :chip_type_id, :integer
  column :sbeams_user, :string
  column :project_id, :integer

  validates_numericality_of :number
  if SiteConfig.using_affy_arrays? && SiteConfig.create_gcos_files?
    validates_presence_of :sbeams_user, :project_id
  end
end

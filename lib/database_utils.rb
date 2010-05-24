class DatabaseUtil
  def self.table_exists?(table_name)
    ActiveRecord::Base.connection.tables.include? table_name.to_s
  end
end

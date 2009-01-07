[NilClass, String, Numeric, Date, Time, TrueClass, FalseClass].each do |cls|
  cls.class_eval do
    include ActiveSupport::CoreExtensions::SimpleType
  end
end
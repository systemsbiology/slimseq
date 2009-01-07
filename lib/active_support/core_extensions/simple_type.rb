module ActiveSupport #:nodoc:
  module CoreExtensions #:nodoc:
    module SimpleType
      def to_xml(options = {})
        tag_name = options[:root] ? options[:root].to_s : self.class.to_s.underscore
        tag_name = tag_name.dasherize  if !options.has_key?(:dasherize) || options[:dasherize]
        type_name = Hash::Conversions::XML_TYPE_NAMES[self.class.name]
        attributes = options[:skip_types] || self.nil? || type_name.nil? ? { } : { :type => type_name }
        options[:builder].instruct! unless options.delete(:skip_instruct)
        if self.nil?
          options[:builder].tag! tag_name, :nil=>true
        else
          options[:builder].tag! tag_name,
            Hash::Conversions::XML_FORMATTING[type_name] ? Hash::Conversions::XML_FORMATTING[type_name].call(self).to_s : self.to_s,
            attributes
        end
      end
    end
  end
end

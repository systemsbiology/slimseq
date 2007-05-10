module Scrubyt
  ##
  #=<tt>Describing actions which interact with the page</tt>
  #
  #This class contains all the actions that are used to navigate on web pages;
  #first of all, *fetch* for downloading the pages - then various actions
  #like filling textfields, submitting formst, clicking links and more
  class NavigationActions
    #These are reserved keywords - they can not be the name of any pattern
    #since they are reserved for describing the navigation
    KEYWORDS = ['fetch',
                'fill_textfield',
                'fill_textarea',
                'submit',
                'click_link',
                'select_option',
                'check_checkbox',
                'end']

    def initialize
        @@current_form = nil
        FetchAction.new
    end

    ##
    #Action to fill a textfield with a query string
    #
    ##*parameters*
    #
    #_textfield_name_ - the name of the textfield (e.g. the name of the google search
    #textfield is 'q'
    #
    #_query_string_ - the string that should be entered into the textfield
    def self.fill_textfield(textfield_name, query_string)
      lookup_form_for_tag('input','textfield',textfield_name,query_string)
      eval("@@current_form['#{textfield_name}'] = '#{query_string}'")
    end

    ##
    #Action to fill a textarea with text
    def self.fill_textarea(textarea_name, text)
      lookup_form_for_tag('textarea','textarea',textarea_name,text)
      eval("@@current_form['#{textarea_name}'] = '#{text}'")
    end

    ##
    #Action for selecting an option from a dropdown box
    def self.select_option(selectlist_name, option)
      lookup_form_for_tag('select','select list',selectlist_name,option)
      select_list = @@current_form.fields.find {|f| f.name == selectlist_name}
      searched_option = select_list.options.find{|f| f.text == option}
      searched_option.click
    end

    def self.check_checkbox(checkbox_name)
      puts checkbox_name
      lookup_form_for_tag('input','checkbox',checkbox_name, '')
      @@current_form.checkboxes.name(checkbox_name).check
    end

    ##
    #Fetch the document
    def self.fetch(*args)
      FetchAction.fetch(*args)
    end
    ##
   #Submit the current form (delegate it to NavigationActions)
    def self.submit(index=nil)
      if index == nil
        FetchAction.submit(@@current_form)
      #----- added by nickmerwin@gmail.com -----
      elsif index.class == String
        button = @@current_form.buttons.detect{|b| b.name == index}
        FetchAction.submit(@@current_form, button)
      #-----------------------------------------
      else
        FetchAction.submit(@@current_form, @@current_form.buttons[index])
      end
    end

    ##
    #Click the link specified by the text ((delegate it to NavigationActions)
    def self.click_link(link_spec,index=0)
      FetchAction.click_link(link_spec,index)
    end

    def self.get_hpricot_doc
      FetchAction.get_hpricot_doc
    end

    def self.get_current_doc_url
      FetchAction.get_current_doc_url
    end

    def self.get_host_name
      FetchAction.get_host_name
    end

private
    def self.lookup_form_for_tag(tag,widget_name,name_attribute,query_string)
      puts "[ACTION] typing #{query_string} into the #{widget_name} named '#{name_attribute}'"
      widget = (FetchAction.get_hpricot_doc/"#{tag}[@name=#{name_attribute}]").map()[0]
      form_tag = Scrubyt::XPathUtils.traverse_up_until_name(widget, 'form')
      find_form_based_on_tag(form_tag, ['name', 'id', 'action'])
    end

    def self.find_form_based_on_tag(tag, possible_attrs)
      lookup_attribute_name = nil
      lookup_attribute_value = nil

      possible_attrs.each { |a|
        lookup_attribute_name = a
        lookup_attribute_value = tag.attributes[a]
        break if lookup_attribute_value != nil
      }
      i = 0
      loop do
        @@current_form = FetchAction.get_mechanize_doc.forms[i]
        return nil if @@current_form == nil
        break if @@current_form.form_node.attributes[lookup_attribute_name] == lookup_attribute_value
        i+= 1
      end
    end#find_form_based_on_tag
  end#end of class NavigationActions
end#end of module Scrubyt

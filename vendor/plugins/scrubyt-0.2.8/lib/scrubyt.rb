#ruby core
require 'open-uri'

#gems
require 'rubygems'
require 'mechanize'
require 'hpricot'
require 'parse_tree'
require 'ruby2ruby'

#scrubyt
require 'scrubyt/utils/ruby_extensions.rb'
require 'scrubyt/utils/xpathutils.rb'
require 'scrubyt/utils/shared_utils.rb'
require 'scrubyt/utils/simple_example_lookup.rb'
require 'scrubyt/utils/compound_example_lookup.rb'
require 'scrubyt/core/scraping/constraint_adder.rb'
require 'scrubyt/core/scraping/constraint.rb'
require 'scrubyt/core/scraping/result_indexer.rb'
require 'scrubyt/core/scraping/pre_filter_document.rb'
require 'scrubyt/core/scraping/compound_example.rb'
require 'scrubyt/output/export.rb'
require 'scrubyt/core/shared/extractor.rb'
require 'scrubyt/core/scraping/filters/base_filter.rb'
require 'scrubyt/core/scraping/filters/attribute_filter.rb'
require 'scrubyt/core/scraping/filters/detail_page_filter.rb'
require 'scrubyt/core/scraping/filters/download_filter.rb'
require 'scrubyt/core/scraping/filters/html_subtree_filter.rb'
require 'scrubyt/core/scraping/filters/regexp_filter.rb'
require 'scrubyt/core/scraping/filters/tree_filter.rb'
require 'scrubyt/core/scraping/pattern.rb'
require 'scrubyt/output/result_dumper.rb'
require 'scrubyt/output/result.rb'
require 'scrubyt/output/post_processor.rb'
require 'scrubyt/core/navigation/navigation_actions.rb'
require 'scrubyt/core/navigation/fetch_action.rb'
require 'scrubyt/core/shared/evaluation_context.rb'
require 'scrubyt/core/shared/u_r_i_builder.rb'
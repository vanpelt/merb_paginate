require 'merb_paginate'
require 'merb_paginate/core_ext'

# This file is hurting the most and needs some love!

module MerbPaginate
  # A mixin for Datamapper. Provides +per_page+ class method
  module Finder
    def self.included(base)
      base.extend ClassMethods
      class << base
        define_method(:per_page) { 30 } unless respond_to?(:per_page)
      end
    end
    
    module ClassMethods
      # This is the main paginating finder.
      #
      # == Special parameters for paginating finders
      # * <tt>:page</tt> -- REQUIRED, but defaults to 1 if false or nil
      # * <tt>:per_page</tt> -- defaults to <tt>CurrentModel.per_page</tt> (which is 30 if not overridden)
      # * <tt>:total_entries</tt> -- use only if you manually count total entries
      # * <tt>:count</tt> -- additional options that are passed on to +count+
      #
      # All other options (+conditions+, +order+, ...) are forwarded to +all+
      # and +count+ calls.
      def paginate(options = {})
        page, per_page, total_entries = wp_parse_options(options)

        MerbPaginate::Collection.create(page, per_page, total_entries) do |pager|
          count_options = options.except :page, :per_page, :total_entries
          find_options = count_options.except(:count).update(:offset => pager.offset, :limit => pager.per_page) 
          
          pager.replace all(find_options)
          
          # magic counting for user convenience:
          pager.total_entries = wp_count(count_options) unless pager.total_entries
        end
      end
      
      # Wraps +find_by_sql+ by simply adding LIMIT and OFFSET to your SQL string
      # based on the params otherwise used by paginating finds: +page+ and
      # +per_page+.
      #
      # Example:
      # 
      #   @developers = Developer.paginate_by_sql ['select * from developers where salary > ?', 80000],
      #                          :page => params[:page], :per_page => 3
      #
      # A query for counting rows will automatically be generated if you don't
      # supply <tt>:total_entries</tt>. If you experience problems with this
      # generated SQL, you might want to perform the count manually in your
      # application.
      # 
      # def paginate_by_sql(sql, options)
      #   WillPaginate::Collection.create(*wp_parse_options(options)) do |pager|
      #     query = sanitize_sql(sql)
      #     original_query = query.dup
      #     # add limit, offset
      #     add_limit! query, :offset => pager.offset, :limit => pager.per_page
      #     # perfom the find
      #     pager.replace find_by_sql(query)
      #     
      #     unless pager.total_entries
      #       count_query = original_query.sub /\bORDER\s+BY\s+[\w`,\s]+$/mi, ''
      #       count_query = "SELECT COUNT(*) FROM (#{count_query}) AS count_table"
      #       # perform the count query
      #       pager.total_entries = count_by_sql(count_query)
      #     end
      #   end
      # end
      
      # ^^^^^
      # FIXME: Too busy to do this right now, someone help me out

      # def respond_to?(method, include_priv = false) #:nodoc:
      #   case method.to_sym
      #   when :paginate, :paginate_by_sql
      #     true
      #   else
      #     super(method, include_priv)
      #   end
      # end
      
      # ^^^^^
      # FIXME: Probly don't need this?

    protected

      # Count it up!
      def wp_count(options)
        excludees = [:count, :order, :limit, :offset, :readonly]
        
        # unless options[:select] and options[:select] =~ /^\s*DISTINCT\b/i
        #   excludees << :select # only exclude the select param if it doesn't begin with DISTINCT
        # end
        
        # ^^^^^^
        # FIXME: Don't need select right now and I'm not even sure how it works in datamapper to be honest
        
        # count expects the same options as find
        count_options = options.except *excludees

        # merge the hash found in :count
        # this allows you to specify :select, :order, or anything else just for the count query
        count_options.update options[:count] if options[:count]

        # we may have to scope ...
        counter = count(count_options)

        count.respond_to?(:length) ? count.length : count
      end

      def wp_parse_options(options) #:nodoc:
        raise ArgumentError, 'parameter hash expected' unless options.respond_to? :symbolize_keys!
        options = options.symbolize_keys!
        raise ArgumentError, ':page parameter required' unless options.key? :page
        
        if options[:count] and options[:total_entries]
          raise ArgumentError, ':count and :total_entries are mutually exclusive'
        end

        page     = options[:page] || 1
        per_page = options[:per_page] || self.per_page
        total    = options[:total_entries]
        [page, per_page, total]
      end

    end
  end
end

DataMapper::Base.class_eval { include MerbPaginate::Finder } # load em up!

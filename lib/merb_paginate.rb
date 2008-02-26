# Blatently copied from WillPaginate

require 'merb_paginate/collection' # only require what's necessary at first

module MerbPaginate
  # You can activate other things on your own...
  def self.activate!(type)
    
    case type
      
    when :datamapper_finder # help out by creating finders for other orms...I will make this more plugable soon
      Merb::BootLoader.before_app_loads do
        require 'merb_paginate/dm_finder'
      end
      
    when :view_helpers
      Merb::BootLoader.before_app_loads do
        require 'merb_paginate/view_helpers'
      end
      
    end
    
  end
end
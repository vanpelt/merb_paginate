# Blatently copied from WillPaginate

require 'merb_paginate/collection' # only require what's necessary at first

module MerbPaginate
  # You can activate other things on your own...
  def self.activate!(type)
    
    if type.is_a?(Hash) && !type[:finder].blank?
      Merb::BootLoader.before_app_loads do
        require 'merb_paginate/finders'
        MerbPaginate::Finders.activate!(type[:finder])
      end
    end
    
    if type == :view_helpers
      Merb::BootLoader.before_app_loads do
        require 'merb_paginate/view_helpers'
      end
    end
    
  end
end
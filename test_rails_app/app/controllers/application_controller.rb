require 'described_routes/helpers/described_routes_helper'

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  include DescribedRoutes::DescribedRoutesHelper
  helper DescribedRoutes::DescribedRoutesHelper

  after_filter :set_link_headers
  
  layout "default"
  
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  protected
  
  def set_link_headers
    set_link_header :self => true, :up => true, :describedby => true, :related => true
  end
end

require 'described_routes/helpers/described_routes_helper'

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  include DescribedRoutes::DescribedRoutesHelper
  helper DescribedRoutes::DescribedRoutesHelper

  before_filter :set_link_header
  layout "default"
  
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
end

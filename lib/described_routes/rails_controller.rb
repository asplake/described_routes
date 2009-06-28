require 'described_routes/rails_routes'
require 'described_routes/helpers/described_routes_helper'
require 'active_support'

module DescribedRoutes
  class RailsController < ActionController::Base
    include DescribedRoutes::DescribedRoutesHelper
    
    def index
      expanded_templates = resource_templates.partial_expand(request.query_parameters)
      
      respond_to do |format|
        format.html { render rescue redirect_to :format => :text } # render index.html.erb or fall back to text
        format.json { render :json => expanded_templates.to_json }
        format.text { render :text => expanded_templates.to_text }
        format.yaml { render :text => expanded_templates.to_yaml }
        format.xml  { render :xml  => expanded_templates.to_xml(Builder::XmlMarkup.new(:indent => 2)).target! }
      end
    end

    def show
      expanded_templates = resource_templates.partial_expand(request.query_parameters)
      resource_template = resource_templates.all_by_name[params[:id]]
      # TODO 404 if nil
      resource_template = resource_template.partial_expand(request.query_parameters)
      
      respond_to do |format|
        format.html { render rescue redirect_to :format => :text } # render show.html.erb or fall back to text
        format.json { render :json => resource_template.to_json }
        format.text { render :text => resource_template.to_text }
        format.yaml { render :text => resource_template.to_yaml }
        format.xml  { render :xml  => resource_template.to_xml(Builder::XmlMarkup.new(:indent => 2)).target! }
      end
    end
  end
end

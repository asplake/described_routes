require 'described_routes/rails_routes'
require 'active_support'

module DescribedRoutes
  class RailsController < ActionController::Base
    def index
      base_url = root_url rescue nil
      resource_templates = RailsRoutes.get_resource_templates(base_url).partial_expand(request.query_parameters)
      
      respond_to do |format|
        format.html # index.html.erb
        format.json { render :json => resource_templates.to_json }
        format.text { render :text => resource_templates.to_text }
        format.yaml { render :text => resource_templates.to_yaml }
        format.xml  { render :xml  => resource_templates.to_xml(Builder::XmlMarkup.new(:indent => 2)).target! }
      end
    end
    
    def show
      base_url = root_url rescue nil
      resource_templates = RailsRoutes.get_resource_templates(base_url).partial_expand(request.query_parameters)
      resource_template = resource_templates.all_by_name[params[:id]]
      # TODO 404 if nil
      resource_template = resource_template.partial_expand(request.query_parameters)
      
      respond_to do |format|
        format.html # show.html.erb
        format.json { render :json => resource_template.to_json }
        format.text { render :text => resource_template.to_text }
        format.yaml { render :text => resource_template.to_yaml }
        format.xml  { render :xml  => resource_template.to_xml(Builder::XmlMarkup.new(:indent => 2)).target! }
      end
    end
  end
end

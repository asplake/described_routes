require 'described_routes/rails_routes'
require 'active_support'

module DescribedRoutes
  class RailsController < ActionController::Base
    def index
      base_url = root_url rescue nil
      resource_templates = RailsRoutes.get_resource_templates(base_url)
      
      respond_to do |format|
        format.html # index.html.erb
        format.json { render :json => ResourceTemplate.to_json(resource_templates) }
        format.text { render :text => ResourceTemplate.to_text(resource_templates) }
        format.yaml do
          yaml = ResourceTemplate::to_yaml(resource_templates)
          yaml = yaml.grep(/(name|rel|path_template|uri_template|resources):|^---/).to_s if ['true', '1'].member?(params["short"])
          render :text => yaml
        end
        format.xml do
          render :xml => ResourceTemplate::to_xml(
                             Builder::XmlMarkup.new(:indent => 2),
                             resource_templates).target!
        end
      end
    end
    
    def show
      base_url = root_url rescue nil
      resources = RailsRoutes.get_resource_templates(base_url)
      resource_template = ResourceTemplate.all_by_name(resources)[params[:id]]
      
      respond_to do |format|
        format.html # show.html.erb
        format.json { render :json => resource_template.to_json }
        format.text { render :text => ResourceTemplate.to_text([resource_template]) }
        format.xml do
          render :xml => resource_template.to_xml(Builder::XmlMarkup.new(:indent => 2)).target!
        end
        format.yaml do
          yaml = resource_template.to_yaml
          yaml = yaml.grep(/(name|rel|path_template|uri_template|resources):|^---/).to_s if ['true', '1'].member?(params["short"])
          render :text => yaml
        end
      end
    end
  end
end

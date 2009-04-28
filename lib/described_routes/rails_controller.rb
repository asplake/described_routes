require 'described_routes/rails_routes'
require 'active_support'

module DescribedRoutes
  class RailsController < ActionController::Base
    def index
      base_url = root_url rescue nil
      resources = RailsRoutes.get_resources(base_url)
      
      respond_to do |format|
        format.html # index.html.erb
        format.json { render :json => resources.to_json }
        format.yaml do
          yaml = resources.to_yaml
          yaml = yaml.grep(/(name|rel|path_template|uri_template|resources):|^---/).to_s if ['true', '1'].member?(params["short"])
          render :text => yaml
        end
        format.xml do
          render :xml => DescribedRoutes::to_xml(
                             Builder::XmlMarkup.new(:indent => 2),
                             resources).target!
        end
      end
    end
  end
end

require 'described_routes/middleware/base'
require 'described_routes/rails_routes'

module DescribedRoutes
  module Middleware
    #
    # Rack middleware that integrates described_routes with Rails.
    #
    # In your environment.rb, add
    #   require "described_routes/middleware/rails"
    # and include
    #   config.middleware.use DescribedRoutes::Middleware::Rails
    # inside your <code>Rails::Initializer.run do...end block</code>
    #
    # Your Rails application will then serve ResourceTemplate data at the configured descrbed_routes path (/described_routes by
    # default and adds link headers to regular requests whose routing matches a ResourceTemplate.
    #
    class Rails < Base
      #
      # Get a ResourceTemplates object from Rails.  Override to suppress sensitive routes.
      #
      def get_resource_templates(root)
        RailsRoutes.get_resource_templates(root)
      end

      #
      # Returns a ResourceTemplate matching the request and its parameter hash, otherwise a pair of nils.  The parameter hash
      # is normalized by removing 'controller' and 'action' members and renaming 'id' (when present) to something resource-specific. 
      #
      def get_resource_routing(req)
        path_parameters  = req.env["action_controller.request.path_parameters"]
        query_parameters = req.env["action_controller.request.query_parameters"]
        
        # Guess the route from the controller and action
        controller_name, action_name = path_parameters["controller"], path_parameters["action"]
        resource_template, id_name = @resource_templates.routing[[controller_name, action_name]]
        
        if resource_template
          params = path_parameters.merge(query_parameters).except("action", "controller")
          if id_name && params[:id]
            params[id_name] = params.delete(:id)
          end
          [resource_template, params]
        else
          [nil, nil]
        end
      end
    end
  end
end

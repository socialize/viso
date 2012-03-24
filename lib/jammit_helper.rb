# Adapted from https://github.com/railsjedi/jammit-sinatra

# jammit/helper assumes ActionView is present
module ActionView
  class Base
  end
end

require 'jammit'
require 'jammit/helper'
require 'jammit/s3_assets_versioning'
require 'padrino-helpers'

module JammitHelper
  def self.registered(app)
    Jammit.load_configuration 'config/assets.yml'

    # Adds #include_stylesheets and #include_javascripts methods
    app.helpers Jammit::Helper

    # Adds #stylesheet_link_tag and #javascript_include_tag methods
    app.helpers Padrino::Helpers
    app.helpers AssetHostInjector

    # Reload assets and prevent packaging on every request in development mode
    if app.development?
      app.before do
        Jammit.reload!
        Jammit.set_package_assets false
      end
    end
  end

  module AssetHostInjector
    include Jammit::S3AssetsVersioning

    # Override Padrino::Helpers#asset_path to use the asset host and path
    # generated by jammit-s3.
    def asset_path(kind, source)
      path = asset_path_proc.call source
      return path if self.class.development?

      host = asset_host_proc.call path, request
      host = "http://assets.my.cld.me"
      File.join(host, path)
    end
  end
end

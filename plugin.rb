# name: rocketchat-sso
# about: Integrate single-signon for Rocket.Chat using Discourse
# version: 1.0.0
# authors: bob-cook
# url: https://github.com/bob-cook/rocketchat-sso

gem 'bson', '4.2.1'
gem 'mongo', '2.4.2'
gem 'domain_name', '0.5.20170404'
gem 'http-cookie', '1.0.3'
gem 'netrc', '0.11.0'
gem 'rest-client', '2.0.2'

enabled_site_setting :rocketchatsso_enabled

load Rails.root.join( 'plugins', 'rocketchat-sso', 'lib', 'engine.rb' ).to_s

def rocketchatsso_require( path )
    require Rails.root.join( 'plugins', 'rocketchat-sso', 'app', path ).to_s
end

after_initialize do

    Discourse::Application.routes.append do
        mount ::RocketChatSso::Engine, at: '/rocketchat-sso'
    end

    require 'mongo'
    require 'rest-client'

    rocketchatsso_require 'controllers/auth_controller.rb'
    rocketchatsso_require 'controllers/users_controller.rb'
    rocketchatsso_require 'jobs/send-users-online.rb'

end

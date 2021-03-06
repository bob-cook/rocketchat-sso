# ----------------------------------------------------------------------------------------

require_dependency 'rc_database.rb'

# ----------------------------------------------------------------------------------------

module RocketChatSso

    # ------------------------------------------------------------------------------------

    class UsersController < ::ApplicationController

        # --------------------------------------------------------------------------------

        requires_plugin 'rocketchat-sso'

        # --------------------------------------------------------------------------------

        #after_filter  :dont_cache_page

        # --------------------------------------------------------------------------------

        def others_online

            # not authorized if no authenticated user, or not enabled

            if current_user.nil?
                render json: { :error => 'Unauthorized' }, status: 401
                return
            end

            if not SiteSetting.rocketchatsso_enabled
                render json: { :error => 'Disabled' }, status: 401
                return
            end

            # open the Rocket.Chat database user collection

            rcdb_client = RocketChatSso.RCDB_Client()

            if rcdb_client.nil?
                Rails.logger.error 'ROCKETCHAT-SSO | RC DB not accessible?'
                render json: { :error => 'rc db connection error' }, status: 500
                return
            end

            rcdb_users_collection = RocketChatSso.RCDB_Users_Collection( rcdb_client )

            if rcdb_users_collection.nil?
                Rails.logger.error 'ROCKETCHAT-SSO | RC DB users collection missing?'
                rcdb_client.close()
                render json: { :error => 'rc db error' }, status: 500
                return
            end

            # retrieve the active Rocket.Chat users other than this one

            rcdb_online = RocketChatSso.RDCB_Find_Online_Users( rcdb_users_collection )

            # count the number of other users

            other_users_online = 0

            if not rcdb_online.nil?

                rcdb_online.each do |user|
                    if user[ 'username' ] != current_user[ 'username' ]
                        other_users_online += 1
                    end
                end

                rcdb_online.close_query()

            end

            # done with the database connection client

            rcdb_client.close()

            # and return the results

            if other_users_online > 0
                Rails.logger.info 'ROCKETCHAT-SSO | found other users online :)'
                render json: { :result => true,
                               :count  => other_users_online }, status: 200
                return
            end

            Rails.logger.info 'ROCKETCHAT-SSO | no other users online :('
            render json: { :result => false }, status: 200
            return

        end

    end

    # ------------------------------------------------------------------------------------

end



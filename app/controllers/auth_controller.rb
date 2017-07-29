# ----------------------------------------------------------------------------------------

require_dependency 'rc_database.rb'
require_dependency 'rc_api.rb'

# ----------------------------------------------------------------------------------------

module RocketChatSso

    # ------------------------------------------------------------------------------------

    class AuthController < ::ApplicationController

        # --------------------------------------------------------------------------------

        requires_plugin 'rocketchat-sso'

        # --------------------------------------------------------------------------------

        after_filter  :dont_cache_page

        # --------------------------------------------------------------------------------

        def authenticate

            # not authorized if no authenticated user, or not enabled

            if current_user.nil?
                render json: { :error => 'Unauthorized' }, status: 401
                return
            end

            if not SiteSetting.rocketchatsso_enabled
                render json: { :error => 'Disabled' }, status: 401
                return
            end

            # open the rocket.chat database user collection

            rcdb_client = RocketChatSso.RCDB_Client()

            if rcdb_client.nil?
                Rails.logger.error 'ROCKETCHAT-SSO | RC DB not accessible?'
                render json: { :error => 'rc db connection error' }, status: 500
                return
            end

            rcdb_users_collection = RocketChatSso.RCDB_Users_Collection( rcdb_client )

            if rcdb_users_collection.nil?

                Rails.logger.error 'rocketchat error: RC DB users collection missing?'

                rcdb_client.close()

                render json: { :error => 'rc db error' }, status: 500
                return

            end

            # retrieve the Rocket.Chat user from the database

            the_rc_user = RocketChatSso.RDCB_Find_User( rcdb_users_collection,
                                                        current_user.username )

            # does the user have an existing token to use?

            if not the_rc_user.nil?

                login_token = the_rc_user[ :services ][ :iframe ][ :token ]

                if not login_token.nil? and login_token != ''

                    Rails.logger.info 'ROCKETCHAT-SSO | existing login for user ' +
                                      current_user.username

                    rcdb_client.close()

                    render json: { :token => login_token }, status: 200
                    return

                end

            end

            # create the user from Rocket.Chat via the API, if none

            if the_rc_user.nil?

                Rails.logger.info 'ROCKETCHAT-SSO | creating user ' +
                                  current_user.username

                rcapi_auth_headers = RocketChatSso.RCAPI_Login()

                if rcapi_auth_headers.nil?
                    Rails.logger.error 'ROCKETCHAT-SSO | RC API login failed'
                    rcdb_client.close()
                    render json: { :error => 'RC API login' }, status: 500
                    return
                end

                new_user = RocketChatSso.RCAPI_Create_User( rcapi_auth_headers,
                                                            current_user.username,
                                                            current_user.name,
                                                            current_user.email )

                avatar_url = SiteSetting.scheme + ":" + current_user.small_avatar_url()

                RocketChatSso.RCAPI_Set_User_Avatar( rcapi_auth_headers,
                                                     current_user.username,
                                                     avatar_url )

                RocketChatSso.RCAPI_Logout( rcapi_auth_headers )

                if new_user.nil?
                    Rails.logger.error 'ROCKETCHAT-SSO | RC API users.create failed'
                    rcdb_client.close()
                    render json: { :error => 'RC API users.create' }, status: 500
                    return
                end

            end

            # save a new login token back to the Rocket.Chat database

            login_token = SecureRandom.base64( 32 )

            the_rc_user = RocketChatSso.RCDB_Update_User_Token( rcdb_users_collection,
                                                                current_user.username,
                                                                login_token )

            if the_rc_user.nil?
                Rails.logger.error 'ROCKETCHAT-SSO | RC DB update failed'
                rcdb_client.close()
                render json: { :error => 'RC DB update' }, status: 500
                return
            end

            # and formulate the JSON response

            Rails.logger.info 'ROCKETCHAT-SSO | successful login for user ' +
                              current_user.username

            rcdb_client.close()

            render json: { :token => login_token }, status: 200
            return

        end

    end

    # ------------------------------------------------------------------------------------

    DiscourseEvent.on( :user_logged_out ) do |user_object|

        if SiteSetting.rocketchatsso_enabled

            Rails.logger.info 'ROCKETCHAT-SSO | user logout: ' + user_object.username

            # open the rocket.chat database user collection

            rcdb_client = RocketChatDatabase.RCDB_Client()

            if not rcdb_client.nil?

                rcdb_users_collection = RocketChatSso.RCDB_Users_Collection( rcdb_client )

                if not rcdb_users_collection.nil?

                    # overwrite the login token to invalidate the session

                    if RocketChatSso.RCDB_Force_User_Logout( rcdb_users_collection,
                                                             user_object.username )
                        Rails.logger.info 'ROCKETCHAT-SSO | user logout db update success'
                    else
                        Rails.logger.error 'ROCKETCHAT-SSO | RC DB user logout failed'
                    end

                end

                # close the database connection

                rcdb_client.close()

            end

        end

    end

    # ------------------------------------------------------------------------------------

end



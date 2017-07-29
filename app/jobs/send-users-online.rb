# ----------------------------------------------------------------------------------------

require_dependency 'rocketchat/rc_database.rb'

# ----------------------------------------------------------------------------------------

module ::Jobs

    # ------------------------------------------------------------------------------------

    class RocketChatSsoBusyUpdate < Jobs::Scheduled
        every 1.minutes

        def execute( args )

            # open the Rocket.Chat database user collection

            rcdb_client = RocketChat.RCDB_Client()

            if rcdb_client.nil?
                Rails.logger.error 'ROCKETCHAT-SSO | RC DB not accessible?'
                return
            end

            rcdb_users_collection = RocketChat.RCDB_Users_Collection( rcdb_client )

            if rcdb_users_collection.nil?
                Rails.logger.error 'ROCKETCHAT-SSO | RC DB users collection missing?'
                rcdb_client.close()
                return
            end

            # retrieve the active (online) Rocket.Chat users

            rcdb_online = RocketChatSso.RDCB_Find_Online_Users( rcdb_users_collection )

            # build an array of the usernames

            users_online_now = []

            if not rcdb_online.nil?

                rcdb_active_users.each do |user|
                    users_online_now.push( user[ 'username' ] )
                end

                rcdb_online.close_query()

            end

            # done with the database connection client

            rcdb_client.close()

            # and publish the results

            MessageBus.publish( '/rocketchat-sso-users-online', users_online_now.as_json )

        end

    end

    # ------------------------------------------------------------------------------------

end


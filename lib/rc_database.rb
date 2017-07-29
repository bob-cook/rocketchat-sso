# ----------------------------------------------------------------------------------------

module RocketChatSso

    # ------------------------------------------------------------------------------------

    def self.RCDB_Client

        db_address = SiteSetting.rocketchatsso_mongodb_server

        if db_address.nil? or db_address == ''
            return nil
        end

        db_url = 'mongodb://' + db_address + '/rocketchat'

        Rails.logger.info 'ROCKETCHAT-SSO | opening RC DB @ ' + db_url

        begin

            mongo_client = Mongo::Client.new( db_url )

            Rails.logger.info 'ROCKETCHAT-SSO | opened RC DB @ ' + db_url

            return mongo_client

        rescue => error
            Rails.logger.error 'ROCKETCHAT-SSO | RC DB failure: ' +
                               '#{error.class} and #{error.message}'
        end

        return nil

    end

    # ------------------------------------------------------------------------------------

    def self.RCDB_Users_Collection( rcdb_mongo_client )

        begin

            mongo_db = rcdb_mongo_client.database
            rc_users = mongo_db[ :users ]

            Rails.logger.info 'ROCKETCHAT-SSO | retrieved RC DB user collection'

            return rc_users

        rescue => error
            Rails.logger.error 'ROCKETCHAT-SSO | RC DB failure: ' +
                               '#{error.class} and #{error.message}'
        end

        return nil

    end

    # ------------------------------------------------------------------------------------

    def self.RDCB_Find_User( rcdb_users_collection, username )

        begin
            u = rcdb_users_collection.find( { :username => username } ).limit( 1 ).first
        rescue => error
            Rails.logger.error 'ROCKETCHAT-SSO | RC DB failure: ' +
                               '#{error.class} and #{error.message}'
            return nil
        end

        if u.nil?
            Rails.logger.error 'ROCKETCHAT-SSO | user not found: ' + username
        end

        return u

    end

    # ------------------------------------------------------------------------------------

    def self.RDCB_Find_Online_Users( rcdb_users_collection )

        query = { :status => 'online', :type => 'user' }

        begin
            other_users = rcdb_users_collection.find( query )
        rescue => error
            Rails.logger.error 'ROCKETCHAT-SSO | RC DB failure: ' +
                               '#{error.class} and #{error.message}'
            return nil
        end

        if other_users.nil?
            Rails.logger.error 'ROCKETCHAT-SSO | db error on query for online users'
        end
    
        return other_users

    end

    # ------------------------------------------------------------------------------------

    def self.RCDB_Update_User_Token( rcdb_users_collection, username, token )

        begin
            u = rcdb_users_collection.find( { :username => username } ).limit( 1 ).first
        rescue => error
            Rails.logger.error 'ROCKETCHAT-SSO | RC DB failure: ' +
                               '#{error.class} and #{error.message}'
            return nil
        end

        if u.nil?
            Rails.logger.error 'ROCKETCHAT-SSO | missing user ' + username
            return nil
        end

        if not u.has_key?( :services )
            u[ :services ] = {}
        end

        if not u[ :services ].has_key?( :iframe )
            u[ :services ][ :iframe ] = {}
        end

        u[ :services ][ :iframe ][ :token ] = token

        begin
            rcdb_users_collection.update_one( { :username => username }, u )
        rescue => error
            Rails.logger.error 'ROCKETCHAT-SSO | RC DB failure: ' +
                               '#{error.class} and #{error.message}'
            return nil
        end

        Rails.logger.info 'ROCKETCHAT-SSO | updated token for user ' + username
        return u

    end

    # ------------------------------------------------------------------------------------

    def self.RCDB_Force_User_Logout( rcdb_users_collection, username )

        begin
            u = rcdb_users_collection.find( { :username => username } ).limit( 1 ).first
        rescue => error
            Rails.logger.error 'ROCKETCHAT-SSO | RC DB failure: ' +
                               '#{error.class} and #{error.message}'
            return false
        end

        if u.nil?
            Rails.logger.error 'ROCKETCHAT-SSO | missing user ' + username
            return false
        end

        if not u.has_key?( :services )
            # nothing to do if there isn't an entry here
            return true
        end

        if u[ :services ].has_key?( :iframe )
            u[ :services ][ :iframe ][ :token ] = ''
        end

        u[ :services ][ :resume ] = {}

        begin
            rcdb_users_collection.update_one( { :username => username }, u )
        rescue => error
            Rails.logger.error 'ROCKETCHAT-SSO | RC DB failure: ' +
                               '#{error.class} and #{error.message}'
            return false
        end

        Rails.logger.info 'ROCKETCHAT-SSO | forced logout for user ' + username
        return true

    end

    # ------------------------------------------------------------------------------------

end


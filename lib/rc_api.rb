# ----------------------------------------------------------------------------------------

module RocketChatSso

    # ------------------------------------------------------------------------------------

    def self.RCAPI_Login

        api_url      = SiteSetting.rocketchatsso_site_url
        api_username = SiteSetting.rocketchatsso_api_username
        api_password = SiteSetting.rocketchatsso_api_password

        if api_url.nil? or api_url == ''
            Rails.logger.error 'ROCKETCHAT-SSO | missing RC site URL?'
            return nil
        end

        if api_username.nil? or api_username == ''
            Rails.logger.error 'ROCKETCHAT-SSO | missing RC API username?'
            return nil
        end

        if api_password.nil? or api_password == ''
            Rails.logger.error 'ROCKETCHAT-SSO | missing RC API password?'
            return nil
        end

        auth_data = { :username => api_username,
                      :password => api_password }

        begin

            rc_login = RestClient::post api_url + '/api/v1/login',
                                        auth_data.to_json,
                                        { :content_type => :json, :accept => :json }

        rescue RestClient::ExceptionWithResponse => e
            Rails.logger.error 'ROCKETCHAT-SSO | API login: ' + e.response
            return nil
        end

        if rc_login.nil? or rc_login.code != 200
            Rails.logger.error 'ROCKETCHAT-SSO | API login failed'
            return nil
        end

        rc_login_data = JSON.parse( rc_login.body )[ 'data' ]

        Rails.logger.info 'ROCKETCHAT-SSO | API login success'

        return { 'X-Auth-Token' => rc_login_data[ 'authToken' ],
                 'X-User-Id'    => rc_login_data[ 'userId' ] }

    end

    # ------------------------------------------------------------------------------------
        
    def self.RCAPI_Logout( rcapi_auth_headers )

        logout_api_url = SiteSetting.rocketchatsso_site_url + '/api/v1/logout'

        begin

            rc_logout = RestClient::Request.execute( method: :get,
                                                     url: logout_api_url,
                                                     headers: rcapi_auth_headers )

        rescue RestClient::ExceptionWithResponse => e
            Rails.logger.error 'ROCKETCHAT-SSO | API logout: ' + e.response
            return
        end

        Rails.logger.info 'ROCKETCHAT-SSO | API logout success'

    end

    # ------------------------------------------------------------------------------------

    def self.RCAPI_Create_User( rcapi_auth_headers, username, fullname, email )

        if fullname.nil? or fullname == ''
            fullname = username
        end

        user_info = { :username => username,
                      :name     => fullname,
                      :email    => email,
                      :password => SecureRandom.base64( 32 ),
                      :active   => true,
                      :verified => true }

        headers = rcapi_auth_headers
        headers[ :content_type ] = :json
        headers[ :accept ]       = :json

        createusers_api_url = SiteSetting.rocketchatsso_site_url + '/api/v1/users.create'

        begin

            rc_create = RestClient::Request.execute( method: :post,
                                                     url: createusers_api_url,
                                                     headers: headers,
                                                     payload: user_info.to_json )

        rescue RestClient::ExceptionWithResponse => e
            Rails.logger.error 'ROCKETCHAT-SSO | API users.create: ' + e.response
            return nil
        end

        if rc_create.nil? or rc_create.code != 200
            Rails.logger.error 'ROCKETCHAT-SSO | API users.create failed'
            return nil
        end

        Rails.logger.info 'ROCKETCHAT-SSO | created user ' + username

        return JSON.parse( rc_create.body )

    end

    # ------------------------------------------------------------------------------------

    def self.RCAPI_Set_User_Avatar( rcapi_auth_headers, username, avatar_url )

        avatar_info = { :username  => username,
                        :avatarUrl => avatar_url }

        headers = rcapi_auth_headers
        headers[ :content_type ] = :json
        headers[ :accept ]       = :json

        setavatar_api_url = SiteSetting.rocketchatsso_site_url + '/api/v1/users.setAvatar'

        begin

            rc_cmd = RestClient::Request.execute( method: :post,
                                                  url: createusers_api_url,
                                                  headers: headers,
                                                  payload: avatar_info.to_json )

        rescue RestClient::ExceptionWithResponse => e
            Rails.logger.error 'ROCKETCHAT-SSO | API users.setAvatar: ' + e.response
            return nil
        end

        if rc_create.nil? or rc_create.code != 200
            Rails.logger.error 'ROCKETCHAT-SSO | API users.setAvatar failed'
            return nil
        end

        Rails.logger.info 'ROCKETCHAT-SSO | avatar for user ' + username + ' set to "' +
                          avatar_url + '"'

        return JSON.parse( rc_cmd.body )

    end

    # ------------------------------------------------------------------------------------

end


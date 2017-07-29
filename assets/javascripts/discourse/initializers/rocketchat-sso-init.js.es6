import Ember from 'ember'
import SiteHeader from 'discourse/components/site-header'
import { ajax } from 'discourse/lib/ajax'
import { withPluginApi } from 'discourse/lib/plugin-api'
import { queryRegistry } from 'discourse/widgets/widget'

export default
{
    name: 'rocketchat-sso-init',

    messageBus: window.MessageBus,

    messageProcessor()
    {
        return function( data, global_id, message_id )
        {
            const user = Discourse.User.current()

            var users_online_besides_me = 0
            data.forEach( function( username )
            {
                if ( username != user[ 'username' ] )
                {
                    users_online_besides_me += 1
                    console.log( 'rocketchat-sso | ' + username )
                }
            } )

            if ( users_online_besides_me > 0 )
            {
                $('#rocketchat-sso-button').css('color', '#266fdc')
            }
            else
            {
                $('#rocketchat-sso-button').css('color', '')
            }
        }
    },

    initialize()
    {
        console.log( 'rocketchat-sso | int()' )
        this.messageBus.subscribe( '/rocketchat-sso-status',
                                   this.messageProcessor() );

        SiteHeader.reopen( {

            didInsertElement()
            {
                const RCSSO_URL  = Discourse.SiteSettings.rocketchatsso_site_url
                const RCSSO_NAME = Discourse.SiteSettings.rocketchatsso_site_name
                const RCSSO_ICON = 'fa.fa-comments'

                this._super()

                Ember.run.scheduleOnce(
                    'afterRender',
                    () => {
                        withPluginApi(
                            '0.1',
                            api => {

                                api.decorateWidget(
                                    'header-icons:before',
                                    helper => {
                                        if (!api.getCurrentUser()) { return [] }
                                        const icon_name = 'i.'
                                                        + RCSSO_ICON
                                                        + '.rocketchat-sso-button-icon'
                                        return helper.h( 'li', [
                                            helper.h( 'a#rocketchat-sso-button',
                                            {
                                                className: 'icon',
                                                href:      RCSSO_URL,
                                                title:     RCSSO_NAME,
                                                target:    '_blank'
                                            },
                                            helper.h( icon_name ) ),
                                        ] )
                                    } )

                                this.queueRerender()

                                ajax( '/rocketchat-sso/others-online',
                                      { method: 'GET'} ).then(
                                        function( result )
                                        {
                                            if ( result[ 'result' ] )
                                            {
                                                $('#rocketchat-sso-button').css('color', '#266fdc')
                                            }
                                            else
                                            {
                                                $('#rocketchat-sso-button').css('color', '')
                                            }
                                        },
                                        function( msg ) { console.log( msg ) }
                                    );

                            }, console.log )
                } )
            }
        } )
    }
}


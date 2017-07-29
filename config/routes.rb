RocketChatSso::Engine.routes.draw do

    get '/auth'          => 'auth#authenticate', defaults: { format: :json }
    get '/others-online' => 'users#others_online', defaults: { format: :json }

end

module Configs
  KEY_TRANSLATIONS[:clientId] = :client_id
  KEY_TRANSLATIONS[:details] = :details
  KEY_TRANSLATIONS[:state] = :state
  KEY_TRANSLATIONS[:largeImage] = :large_image
  KEY_TRANSLATIONS[:smallImage] = :small_image
  KEY_TRANSLATIONS[:webhookUrl] = :webhook_url
  
  module Project
    class Discord
      attr_accessor :client_id
      attr_accessor :details
      attr_accessor :state
      attr_accessor :large_image
      attr_accessor :small_image
      attr_accessor :webhook_url
    end
  end
  
  register(:discord, 'discord_config', :json, false, Project::Discord)
end

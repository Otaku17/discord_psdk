module Configs
  # Key translation mapping for configuration keys
  #
  # @return [Hash<Symbol, Symbol>]
  KEY_TRANSLATIONS[:clientId]    = :client_id
  KEY_TRANSLATIONS[:details]     = :details
  KEY_TRANSLATIONS[:state]       = :state
  KEY_TRANSLATIONS[:largeImage]  = :large_image
  KEY_TRANSLATIONS[:smallImage]  = :small_image
  KEY_TRANSLATIONS[:largeText]   = :large_text
  KEY_TRANSLATIONS[:smallText]   = :small_text
  KEY_TRANSLATIONS[:webhookUrl]  = :webhook_url
  KEY_TRANSLATIONS[:color]       = :color
  KEY_TRANSLATIONS[:title]       = :title
  KEY_TRANSLATIONS[:url]         = :url
  KEY_TRANSLATIONS[:authorName]  = :author_name
  KEY_TRANSLATIONS[:authorIcon]  = :author_icon
  KEY_TRANSLATIONS[:authorUrl]   = :author_url
  KEY_TRANSLATIONS[:thumbnail]   = :thumbnail
  KEY_TRANSLATIONS[:description] = :description
  KEY_TRANSLATIONS[:image]       = :image
  KEY_TRANSLATIONS[:footerIcon]  = :footer_icon
  KEY_TRANSLATIONS[:footerText]  = :footer_text 
  
  module Project
    class Discord
      ########################
      # Rich Presence Config #
      ########################
      
      # Discord Application ID
      #
      # @return [String]
      attr_accessor :client_id
      
      # Details text for Rich Presence
      #
      # @return [String]
      attr_accessor :details
      
      # State text for Rich Presence
      #
      # @return [String]
      attr_accessor :state
      
      # Large image key for Rich Presence
      #
      # @return [String]
      attr_accessor :large_image
      
      # Small image key for Rich Presence
      #
      # @return [String]
      attr_accessor :small_image
      
      # Text displayed when hovering over large image
      #
      # @return [String]
      attr_accessor :large_text
      
      # Text displayed when hovering over small image
      #
      # @return [String]
      attr_accessor :small_text
      
      ##################
      # Webhook Config #
      ##################
      
      # Discord webhook URL
      #
      # @return [String]
      attr_accessor :webhook_url
      
      ################
      # EMBED Config #
      ################
      
      # Embed color as integer or hex string
      #
      # @return [String]
      attr_accessor :color
      
      # Embed title
      #
      # @return [String]
      attr_accessor :title
      
      # Embed URL
      #
      # @return [String]
      attr_accessor :url
      
      # Embed author name
      #
      # @return [String]
      attr_accessor :author_name
      
      # Embed author icon URL
      #
      # @return [String]
      attr_accessor :author_icon
      
      # Embed author URL
      #
      # @return [String]
      attr_accessor :author_url
      
      # Embed thumbnail image URL
      #
      # @return [String]
      attr_accessor :thumbnail
      
      # Embed description
      #
      # @return [String]
      attr_accessor :description
      
      # Embed main image URL
      #
      # @return [String]
      attr_accessor :image
      
      # Embed footer icon URL
      #
      # @return [String]
      attr_accessor :footer_icon
      
      # Embed footer text
      #
      # @return [String]
      attr_accessor :footer_text
    end
  end
  
  # Register Discord configuration in Configs system
  #
  # @return [void]
  register(:discord, 'discord_config', :json, false, Project::Discord)
end

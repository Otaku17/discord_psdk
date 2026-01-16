require "time"

module Discord
  module Webhook
    module_function

    # =========================
    # Utils
    # =========================

    # Prevent Discord mentions (@everyone, roles, users) in a string.
    #
    # @param value [String] The string to sanitize.
    # @return [String]
    def sanitize_mentions(value)
      return value unless value.is_a?(String)
      value.gsub("@", "")
    end

    # Remove nil values recursively from a Hash or Array.
    #
    # @param obj [Object] The object to compact.
    # @return [Object] The cleaned object without nil values.
    def compact_hash(obj)
      case obj
      when Hash
        obj.each_with_object({}) do |(k, v), h|
          next if v.nil?
          cleaned = compact_hash(v)
          h[k] = cleaned unless cleaned.nil?
        end
      when Array
        obj.map { |v| compact_hash(v) }.compact
      when String
        sanitize_mentions(obj)
      else
        obj
      end
    end

    # =========================
    # Webhook Sender
    # =========================

    # Send a message to a Discord webhook.
    #
    # @param url [String] The webhook URL.
    # @param content [String, nil] The message content.
    # @param username [String, nil] Override the webhook username.
    # @param avatar_url [String, nil] Override the webhook avatar.
    # @param embeds [Array, nil] List of embed hashes.
    # @param silent [Boolean] Suppress errors if true.
    # @return [Net::HTTPResponse, nil] The HTTP response or nil if silent.
    def send(
      url: Configs.discord.webhook_url,
      content: nil,
      username: nil,
      avatar_url: nil,
      embeds: nil,
      silent: true
    )
      uri = URI.parse(url)

      payload = {}
      payload[:content]    = sanitize_mentions(content)    if content
      payload[:username]   = sanitize_mentions(username)   if username
      payload[:avatar_url] = avatar_url if avatar_url
      payload[:embeds]     = embeds if embeds

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 3
      http.read_timeout = 5

      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] = "application/json"
      request.body = payload.to_json

      http.request(request)

    rescue StandardError => e
      raise e unless silent
      warn "[Discord::Webhook] skipped (#{e.class})"
      nil
    end

    # Return a new EmbedBuilder instance.
    #
    # @return [EmbedBuilder]
    def embed
      EmbedBuilder.new
    end

    # =========================
    # Embed Builder
    # =========================

    class EmbedBuilder
      # Initialize an empty embed with default config values.
      #
      # @return [void]
      def initialize
        @embed = {
          title:       Configs.discord.title,
          url:         Configs.discord.url,
          description: Configs.discord.description,
          color:       parse_color(Configs.discord.color),
          fields:      [],
          author: {
            name:     Configs.discord.author_name,
            icon_url: Configs.discord.author_icon,
            url:       Configs.discord.author_url
          },
          thumbnail: {
            url: Configs.discord.thumbnail
          },
          image: {
            url: Configs.discord.image
          },
          footer: {
            text:     Configs.discord.footer_text,
            icon_url: Configs.discord.footer_icon
          }
        }
      end

      # =========================
      # Basic fields
      # =========================

      # Set the embed title.
      #
      # @param value [String] The title text.
      # @return [self]
      def title(value)
        @embed[:title] = value
        self
      end

      # Set the embed URL.
      #
      # @param value [String] The URL.
      # @return [self]
      def url(value)
        @embed[:url] = value
        self
      end

      # Set the embed description.
      #
      # @param value [String] The description text.
      # @return [self]
      def description(value)
        @embed[:description] = value
        self
      end

      # Set the embed color.
      #
      # @param value [Integer, String] The color as integer or hex string.
      # @return [self]
      def color(value)
        @embed[:color] = parse_color(value)
        self
      end

      # =========================
      # Rich fields
      # =========================

      # Add a field to the embed.
      #
      # @param name [String] Field name.
      # @param value [String] Field value.
      # @param inline [Boolean] Whether field is inline.
      # @return [self]
      def field(name, value, inline: false)
        @embed[:fields] << {
          name: name.to_s,
          value: value.to_s,
          inline: inline
        }
        self
      end

      # Set the embed footer.
      #
      # @param text [String, nil] Footer text.
      # @param icon_url [String, nil] Footer icon URL.
      # @return [self]
      def footer(text = nil, icon_url: nil)
        @embed[:footer] ||= {}
        @embed[:footer][:text] = text unless text.nil?
        @embed[:footer][:icon_url] = icon_url unless icon_url.nil?
        self
      end

      # Set the embed author.
      #
      # @param name [String, nil] Author name.
      # @param icon_url [String, nil] Author icon URL.
      # @param url [String, nil] Author URL.
      # @return [self]
      def author(name = nil, icon_url: nil, url: nil)
        @embed[:author] ||= {}
        @embed[:author][:name] = name unless name.nil?
        @embed[:author][:icon_url] = icon_url unless icon_url.nil?
        @embed[:author][:url] = url unless url.nil?
        self
      end

      # Set the embed thumbnail.
      #
      # @param url [String, nil] Thumbnail URL.
      # @return [self]
      def thumbnail(url = nil)
        @embed[:thumbnail] ||= {}
        @embed[:thumbnail][:url] = url unless url.nil?
        self
      end

      # Set the embed image.
      #
      # @param url [String, nil] Image URL.
      # @return [self]
      def image(url = nil)
        @embed[:image] ||= {}
        @embed[:image][:url] = url unless url.nil?
        self
      end

      # Set the embed timestamp.
      #
      # @param time [Time] Timestamp to set (default: now).
      # @return [self]
      def timestamp(time = Time.now)
        @embed[:timestamp] = time.utc.iso8601
        self
      end

      # =========================
      # Final payload
      # =========================

      # Convert the embed to a Discord-compatible hash.
      #
      # @return [Hash]
      def to_h
        data = Discord::Webhook.compact_hash(@embed)
        data.delete(:fields) if data[:fields]&.empty?
        data
      end

      private

      # Parse a color string or integer to integer.
      #
      # @param value [Integer, String, nil] The color.
      # @return [Integer, nil]
      def parse_color(value)
        return if value.nil?
        return value if value.is_a?(Integer)
        value.to_s.delete("#").to_i(16)
      end
    end
  end
end

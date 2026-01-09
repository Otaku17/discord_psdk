require "json"
require "net/http"
require "uri"
require "time"

module Discord
  module Webhook
    module_function

    # Send a Discord webhook message.
    #
    # @param url [String]
    #   Webhook URL
    #
    # @param content [String, nil]
    #   Plain text message
    #
    # @param embeds [Array<Hash>, nil]
    #   Embed payloads (EmbedBuilder#to_h)
    #
    # @return [Net::HTTPResponse]
    def send(
      url: Configs.discord.webhook_url,
      content: nil,
      username: nil,
      avatar_url: nil,
      embeds: nil
    )
      uri = URI.parse(url)

      payload = {}
      payload[:content]    = content    if content
      payload[:username]   = username   if username
      payload[:avatar_url] = avatar_url if avatar_url
      payload[:embeds]     = embeds     if embeds

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"

      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] = "application/json"
      request.body = payload.to_json

      http.request(request)
    end

    # Create an embed builder.
    #
    # @return [EmbedBuilder]
    def embed
      EmbedBuilder.new
    end

    # =========================
    # Embed Builder DSL
    # =========================
    class EmbedBuilder
      def initialize
        @embed = { fields: [] }
      end

      # @param value [String]
      # @return [EmbedBuilder]
      def title(value)
        @embed[:title] = value
        self
      end

      # @param value [String]
      # @return [EmbedBuilder]
      def description(value)
        @embed[:description] = value
        self
      end

      # @param value [Integer, String]
      # @return [EmbedBuilder]
      def color(value)
        @embed[:color] = parse_color(value)
        self
      end

      # @param value [String]
      # @return [EmbedBuilder]
      def url(value)
        @embed[:url] = value
        self
      end

      # @param name [String]
      # @param value [String]
      # @param inline [Boolean]
      # @return [EmbedBuilder]
      def field(name, value, inline: false)
        @embed[:fields] << {
          name: name.to_s,
          value: value.to_s,
          inline: inline
        }
        self
      end

      # @return [EmbedBuilder]
      def footer(text, icon_url: nil)
        @embed[:footer] = { text: text }
        @embed[:footer][:icon_url] = icon_url if icon_url
        self
      end

      # @return [EmbedBuilder]
      def author(name, icon_url: nil, url: nil)
        @embed[:author] = { name: name }
        @embed[:author][:icon_url] = icon_url if icon_url
        @embed[:author][:url]      = url if url
        self
      end

      # @return [EmbedBuilder]
      def thumbnail(url)
        @embed[:thumbnail] = { url: url }
        self
      end

      # @return [EmbedBuilder]
      def image(url)
        @embed[:image] = { url: url }
        self
      end

      # @param time [Time]
      # @return [EmbedBuilder]
      def timestamp(time = Time.now)
        @embed[:timestamp] = time.utc.iso8601
        self
      end

      # Convert to Discord-compatible hash.
      #
      # @return [Hash]
      def to_h
        data = @embed.dup
        data.delete(:fields) if data[:fields].empty?
        data
      end

      private

      def parse_color(value)
        return value if value.is_a?(Integer)
        value.delete("#").to_i(16)
      end
    end
  end
end

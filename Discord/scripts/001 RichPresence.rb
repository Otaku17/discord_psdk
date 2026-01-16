module Discord
  module RichPresence
    module_function

    # =========================
    # Discord IPC Opcodes
    # =========================

    # Opcode for handshake.
    #
    # @return [Integer]
    OPCODE_HANDSHAKE = 0

    # Opcode for sending frames.
    #
    # @return [Integer]
    OPCODE_FRAME     = 1

    # Discord Application ID.
    #
    # @return [String]
    CLIENT_ID = Configs.discord.client_id

    # =========================
    # Internal State
    # =========================

    @mutex      = Mutex.new
    @thread     = nil
    @socket     = nil
    @running    = false
    @paused     = false
    @start_time = Time.now.to_i
    @activity   = {}

    # Interval in seconds to send keep-alive pings.
    #
    # @return [Integer]
    KEEP_ALIVE_INTERVAL = 15

    # =========================
    # Public API
    # =========================

    # Start the Rich Presence thread.
    #
    # @return [void]
    def start
      @mutex.synchronize do
        return if @running
        @running = true
        @paused  = false
      end

      @thread = Thread.new { rpc_loop }
    end

    # Stop the Rich Presence thread and clear activity.
    #
    # @return [void]
    def stop
      @mutex.synchronize do
        @running = false
        @paused  = false
      end

      clear_activity rescue nil
      close_socket
      @thread&.kill
      @thread = nil
    end

    # Pause Rich Presence updates.
    #
    # @return [void]
    def pause
      @mutex.synchronize do
        return unless @running
        return if @paused
        @paused = true
      end

      clear_activity rescue nil
    end

    # Resume Rich Presence updates.
    #
    # @return [void]
    def resume
      @mutex.synchronize do
        return unless @running
        return unless @paused
        @paused = false
      end

      send_activity rescue nil
    end

    # Check if Rich Presence updates are paused.
    #
    # @return [Boolean]
    def paused?
      @paused
    end

    # =========================
    # Activity Update
    # =========================

    # Update the current activity.
    #
    # @param details [String, :__keep__] The details text (leave unchanged with :__keep__).
    # @param state [String, :__keep__] The state text (leave unchanged with :__keep__).
    # @param assets [Hash, nil] Assets to merge into the activity.
    # @return [void]
    def update(details: :__keep__, state: :__keep__, assets: nil)
      @mutex.synchronize do
        @activity[:details] = details unless details == :__keep__
        @activity[:state]   = state   unless state   == :__keep__

        if assets
          @activity[:assets] ||= {}
          assets.each { |k, v| @activity[:assets][k] = v }
        end
      end

      send_activity rescue nil unless @paused
    end

    # =========================
    # Main RPC Loop
    # =========================

    # The main loop that maintains the IPC connection and sends keep-alive pings.
    #
    # @return [void]
    def rpc_loop
      last_ping = Time.now.to_i

      while @running
        begin
          unless connected?
            connect_and_handshake
            build_initial_activity
            send_activity unless @paused
          end

          if !@paused && Time.now.to_i - last_ping >= KEEP_ALIVE_INTERVAL
            send_ping
            last_ping = Time.now.to_i
          end

          sleep 1
        rescue
          close_socket
          sleep 2
        end
      end
    end

    # =========================
    # Activity Handling
    # =========================

    # Build the initial Discord Rich Presence activity object.
    #
    # @return [Hash] The initialized activity hash.
    def build_initial_activity
      @activity = {
        details: Configs.discord.details,
        state:   Configs.discord.state,
        assets: {
          large_image: Configs.discord.large_image,
          large_text:  Configs.discord.large_text,
          small_image: Configs.discord.small_image,
          small_text:  Configs.discord.small_text
        }
      }
    end

    # Remove nil keys recursively from a hash.
    #
    # @param hash [Hash] The hash to clean.
    # @return [Hash] A new hash with nil values removed.
    def compact_hash(hash)
      hash.each_with_object({}) do |(k, v), h|
        next if v.nil?
        h[k] = v.is_a?(Hash) ? compact_hash(v) : v
      end
    end

    # Send the current activity to Discord.
    #
    # @return [void]
    def send_activity
      activity = compact_hash(
        @activity.merge(
          timestamps: { start: @start_time }
        )
      )

      payload = {
        cmd: "SET_ACTIVITY",
        nonce: rand(1_000_000).to_s,
        args: {
          pid: Process.pid,
          activity: activity
        }
      }

      send_packet(@socket, OPCODE_FRAME, payload)
    end

    # Clear the current Discord activity.
    #
    # @return [void]
    def clear_activity
      payload = {
        cmd: "SET_ACTIVITY",
        nonce: rand(1_000_000).to_s,
        args: { pid: Process.pid, activity: nil }
      }

      send_packet(@socket, OPCODE_FRAME, payload)
    end

    # =========================
    # IPC Core
    # =========================

    # Connect to Discord IPC and perform handshake.
    #
    # @return [void]
    def connect_and_handshake
      @socket = connect

      send_packet(@socket, OPCODE_HANDSHAKE, {
        v: 1,
        client_id: CLIENT_ID
      })

      wait_ready(@socket)
    end

    # Check if the IPC socket is connected.
    #
    # @return [Boolean]
    def connected?
      @socket && !@socket.closed?
    end

    # Send a ping to Discord to keep the connection alive.
    #
    # @return [void]
    def send_ping
      send_packet(@socket, OPCODE_FRAME, { cmd: "PING" })
    end

    # =========================
    # Platform IPC Paths
    # =========================

    # Attempt to connect to the Discord IPC socket.
    #
    # @return [IO, nil] The connected socket, or nil if none found.
    def connect
      ipc_paths.each do |path|
        begin
          case RUBY_PLATFORM
          when /mswin|mingw|cygwin/
            socket = File.open(path, "r+b")
          when /linux|darwin/
            socket = UNIXSocket.new(path)
          else
            next
          end

          socket.sync = true
          return socket
        rescue
          next
        end
      end

      nil
    end

    # Generate potential IPC socket paths based on platform.
    #
    # @return [Array<String>] List of possible IPC paths.
    def ipc_paths
      case RUBY_PLATFORM
      when /mswin|mingw|cygwin/
        (0..9).map { |i| "\\\\.\\pipe\\discord-ipc-#{i}" }
      when /linux/
        uid = Process.uid
        paths = (0..9).map { |i| "/run/user/#{uid}/discord-ipc-#{i}" }

        if ENV["XDG_RUNTIME_DIR"]
          paths += (0..9).map { |i| "#{ENV["XDG_RUNTIME_DIR"]}/discord-ipc-#{i}" }
        end

        paths
      when /darwin/
        tmp = ENV["TMPDIR"] || "/tmp"
        (0..9).map { |i| File.join(tmp, "discord-ipc-#{i}") }
      else
        []
      end
    end

    # =========================
    # Low-level IPC
    # =========================

    # Wait for Discord to acknowledge the handshake.
    #
    # @param socket [IO] The IPC socket.
    # @return [Hash] Parsed JSON response.
    def wait_ready(socket)
      header = socket.read(8)
      _, len = header.unpack("L<L<")
      JSON.parse(socket.read(len))
    end

    # Send a packet to Discord via the IPC socket.
    #
    # @param socket [IO] The IPC socket.
    # @param opcode [Integer] The Discord IPC opcode.
    # @param data [Hash] The payload to send.
    # @return [void]
    def send_packet(socket, opcode, data)
      return unless socket && !socket.closed?

      json   = data.to_json
      header = [opcode, json.bytesize].pack("L<L<")
      socket.write(header)
      socket.write(json)
    end

    # Close the IPC socket if open.
    #
    # @return [void]
    def close_socket
      @socket&.close rescue nil
      @socket = nil
    end
  end
end

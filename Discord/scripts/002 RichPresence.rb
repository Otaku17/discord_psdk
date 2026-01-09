module Discord
  module RichPresence
    module_function

    # =========================
    # Discord IPC Opcodes
    # =========================
    OPCODE_HANDSHAKE = 0
    OPCODE_FRAME     = 1

    # Discord Application ID
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

    # Interval (seconds) between keep-alive pings
    KEEP_ALIVE_INTERVAL = 15

    # =========================
    # Public API
    # =========================

    # Start Discord Rich Presence.
    #
    # @return [void]
    #
    # Side effects:
    # - Opens Discord IPC connection
    # - Spawns a background thread
    # - Sends initial activity
    #
    # Notes:
    # - Non-blocking
    # - Safe to call multiple times
    def start
      @mutex.synchronize do
        return if @running
        @running = true
        @paused  = false
      end

      @thread = Thread.new { rpc_loop }
    end

    # Stop Rich Presence entirely.
    #
    # @return [void]
    #
    # Side effects:
    # - Clears Discord activity
    # - Closes IPC socket
    # - Kills background thread
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

    # Temporarily hide Rich Presence.
    #
    # @return [void]
    #
    # Side effects:
    # - Clears Discord activity
    # - Keeps IPC connection alive
    def pause
      @mutex.synchronize do
        return unless @running
        return if @paused
        @paused = true
      end

      clear_activity rescue nil
    end

    # Restore Rich Presence after pause.
    #
    # @return [void]
    #
    # Side effects:
    # - Re-sends last activity to Discord
    def resume
      @mutex.synchronize do
        return unless @running
        return unless @paused
        @paused = false
      end

      send_activity rescue nil
    end

    # Check pause state.
    #
    # @return [Boolean]
    def paused?
      @paused
    end

    # Update Rich Presence fields.
    #
    # @param details [String, nil]
    #   Primary activity text
    #
    # @param state [String, nil]
    #   Secondary activity text
    #
    # @param assets [Hash, nil]
    #   Asset overrides (large_image, small_image, etc.)
    #
    # @return [void]
    #
    # Notes:
    # - Only provided fields are updated
    # - Automatically sent unless paused
    def update(details: nil, state: nil, assets: nil)
      @mutex.synchronize do
        @activity[:details] = details if details
        @activity[:state]   = state   if state

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

    # Background RPC loop.
    #
    # @return [void]
    #
    # Internal:
    # - Handles reconnects
    # - Sends keep-alive pings
    # - Silent error recovery
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

    # Build activity from configuration.
    #
    # @return [void]
    def build_initial_activity
      @activity = {
        details: Configs.discord.details,
        state:   Configs.discord.state,
        assets: {
          large_image: Configs.discord.large_image,
          small_image: Configs.discord.small_image
        }
      }
    end

    # Send current activity to Discord.
    #
    # @return [void]
    def send_activity
      payload = {
        cmd: "SET_ACTIVITY",
        nonce: rand(1_000_000).to_s,
        args: {
          pid: Process.pid,
          activity: {
            **@activity,
            timestamps: { start: @start_time }
          }
        }
      }

      send_packet(@socket, OPCODE_FRAME, payload)
    end

    # Clear activity from Discord UI.
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

    # Perform IPC handshake.
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

    # Check socket state.
    #
    # @return [Boolean]
    def connected?
      @socket && !@socket.closed?
    end

    # Send keep-alive ping.
    #
    # @return [void]
    def send_ping
      send_packet(@socket, OPCODE_FRAME, { cmd: "PING" })
    end

    # =========================
    # Platform IPC Paths
    # =========================

    # Open Discord IPC socket.
    #
    # @return [File]
    # @raise [RuntimeError] if IPC not found
    def connect
      ipc_paths.each do |path|
        next unless File.exist?(path)

        begin
          case RUBY_PLATFORM
          when /mswin|mingw|cygwin/
            return File.open(path, "r+b")
          when /linux|darwin/
            return UNIXSocket.new(path)
          end
        rescue
          next
        end
      end

      return nil
    end

    # List IPC paths by platform.
    #
    # @return [Array<String>]
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

        return paths
      when /darwin/
        tmp = ENV["TMPDIR"] || "/tmp"
        (0..9).map { |i| File.join(tmp, "discord-ipc-#{i}") }
      else
        return []
      end
    end

    # =========================
    # Low-level IPC
    # =========================

    # Wait for Discord READY payload.
    #
    # @param socket [File]
    # @return [Hash]
    def wait_ready(socket)
      header = socket.read(8)
      _, len = header.unpack("L<L<")
      JSON.parse(socket.read(len))
    end

    # Send raw IPC packet.
    #
    # @param socket [File]
    # @param opcode [Integer]
    # @param data [Hash]
    # @return [void]
    def send_packet(socket, opcode, data)
      return unless socket && !socket.closed?

      json   = data.to_json
      header = [opcode, json.bytesize].pack("L<L<")
      socket.write(header)
      socket.write(json)
    end

    # Close IPC socket.
    #
    # @return [void]
    def close_socket
      @socket&.close rescue nil
      @socket = nil
    end
  end
end

# Discord Integration (Rich Presence & Webhook)

> Discord integration for Ruby / Pokémon SDK projects  
> Rich Presence (IPC) + Webhook (HTTP) with a clean DSL

## Overview

This module provides a **full Discord integration** for PSDK projects:

- **Discord Rich Presence**
  - Native IPC (Windows / Linux / macOS)
  - Background thread (non-blocking)
  - Pause / Resume / Dynamic updates
- **Discord Webhook**
  - Simple message sending
  - Fluent DSL for building Discord embeds
  - Official Discord API compatible

No runtime setup needed — everything is loaded from config files.

---

## Installation

1. Place the plugin in your project/scripts:

   ```
   Discord.psdkplug
   ```

2. Run this command at the root of your project:

   ```bash
   .\psdk --util=plugin load
   ```

3. Configure Discord settings (`Data/configs/discord_config.json`).
   ```json
   {
     "client_id": "YOUR_DISCORD_APP_ID",
     "details": "Playing the game",
     "state": "Main Menu",
     "large_image": "game_logo",
     "small_image": "game_logo",
     "webhook_url": "https://discord.com/api/webhooks/..."
   }
   ```

---

## Discord Rich Presence

### Start Rich Presence

```ruby
Discord::RichPresence.start
```

- Non-blocking
- Safe to call multiple times
- Automatically connects to Discord

### Pause / Resume

```ruby
Discord::RichPresence.pause
Discord::RichPresence.resume
```

- `pause` hides the activity
- `resume` restores the previous one

### Update Activity

```ruby
Discord::RichPresence.update(
  details: "In battle",
  state: "Arena",
  assets: {
    large_image: "arena",
    small_image: "player"
  }
)
```

Only provided fields are updated.

### Stop Rich Presence

```ruby
Discord::RichPresence.stop
```

- Clears activity
- Closes IPC connection
- Stops background thread

---

## Discord Webhook

### Send a simple message

```ruby
Discord::Webhook.send(
  content: "Server is online!"
)
```

### Embed DSL

Embeds are built using a fluent, chainable DSL.

```ruby
embed = Discord::Webhook.embed
  .title("Server Status")
  .description("Live game server information")
  .color("#5865F2")
  .field("Players", "12 / 64", inline: true)
  .field("Map", "Arena", inline: true)
  .footer("My Game")
  .timestamp
```

Send it:

```ruby
Discord::Webhook.send(
  embeds: [embed.to_h]
)
```

### Content + Embed

```ruby
Discord::Webhook.send(
  content: "Game update",
  embeds: [embed.to_h]
)
```

---

## Notes & Best Practices

- All webhook fields are optional
- Embeds must be passed as `Array<Hash>`
- Rich Presence runs in its own thread
- Errors are silently handled to avoid crashes
- Safe for game loops and real-time apps

---

## Platform Compatibility

| OS      | Status                             |
| ------- | ---------------------------------- |
| Windows | ✅ Native IPC                      |
| Linux   | ✅ `/run/user` / `XDG_RUNTIME_DIR` |
| macOS   | ✅ `/tmp/discord-ipc-*`            |

---

## License

Free to use, modify, and distribute.  
No warranty — use at your own risk.

---

## Credits

Made with ❤️ for Pokémon SDK & Ruby projects.  
Inspired by Discord IPC & Webhook APIs.

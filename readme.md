<p align="center">
  <img src="https://cdn.discordapp.com/attachments/1457770649970802779/1472596616438612078/logo_github.png?ex=699325f8&is=6991d478&hm=f51643db05c10dfc41b2a3a125e1e46fba6ee140126b4f390c6b3a3665081a61&" width="300">
</p>

# Discord Integration (Rich Presence & Webhook)

> Discord integration for Ruby / Pokémon SDK projects  
> Rich Presence (IPC) + Webhook (HTTP) with a clean DSL
---

## Installation / Update

1. Place the plugin in your project/scripts:

   ```
   Discord.psdkplug
   ```

2. Run this command at the root of your project:

   ```bash
   .\psdk --util=plugin load
   ```

3. Configure Discord settings (`Data/configs/discord_config.json`).

Here’s an example of a typical Rich Presence activity setup:


https://github.com/user-attachments/assets/c5ce840a-53da-43a9-8ebd-f264980f13f0

## Start Rich Presence

```ruby
Discord::RichPresence.start
```

| Field | Required | Description |
|------|---------|-------------|
| client_id | ✅ | Discord Application ID |



## Update Activity

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

### Activity Object (Official)

| Field | Required | Type | Notes |
|-----|---------|------|------|
| details | ❌ | String | Max 128 chars |
| state | ❌ | String | Max 128 chars |
| timestamps.start | ❌ | Integer | Unix timestamp |
| assets.large_image | ❌ | String | Asset key |
| assets.large_text | ❌ | String | Hover text |
| assets.small_image | ❌ | String | Asset key |
| assets.small_text | ❌ | String | Hover text |

> Only provided fields are sent. `nil` removes the field.


## Pause / Resume

```ruby
Discord::RichPresence.pause
Discord::RichPresence.resume
```

| Method | Effect |
|------|-------|
| pause | Clears activity |
| resume | Restores last activity |


## Stop Rich Presence

```ruby
Discord::RichPresence.stop
```

- Closes IPC socket
- Stops background thread


# DISCORD WEBHOOK API

Based on **official Discord Webhook & Embed API**.

## Send Message

```ruby
Discord::Webhook.send(content: "Server online")
```

| Field | Required | Type |
|------|---------|------|
| webhook_url | ✅ | String |
| content | ❌ | String |
| username | ❌ | String |
| avatar_url | ❌ | String |
| embeds | ❌ | Array<Embed> |

## Embed Builder DSL

```ruby
embed = Discord::Webhook.embed
  .title("Status")
  .description("Server running")
  .color("#5865F2")
  .timestamp
```

Send it:

```ruby
Discord::Webhook.send(
  embeds: [embed.to_h]
)
```

## Embed Object (Official Discord API)

| Field | Required | Type | Limits |
|------|---------|------|--------|
| title | ❌ | String | 256 chars |
| description | ❌ | String | 4096 chars |
| url | ❌ | String | Valid URL |
| timestamp | ❌ | ISO8601 | |
| color | ❌ | String | HEX |

### Author Object

| Field | Required | Type |
|------|---------|------|
| name | ❌ | String |
| url | ❌ | String |
| icon_url | ❌ | String |

### Footer Object

| Field | Required | Type |
|------|---------|------|
| text | ❌ | String |
| icon_url | ❌ | String |

### Image / Thumbnail

| Field | Required | Type |
|------|---------|------|
| url | ❌ | String |

### Fields Array

| Field | Required | Type | Limits |
|------|---------|------|--------|
| name | ✅ | String | 256 chars |
| value | ✅ | String | 1024 chars |
| inline | ❌ | Boolean | |


## Limits (Discord Enforced)

- Max embeds per message: **10**
- Max fields per embed: **25**
- Total embed size: **6000 chars**


### Content + Embed

```ruby
Discord::Webhook.send(
  content: "Game update",
  embeds: [embed.to_h]
)
```

## Security

### Mention Protection

- Removes all `@` characters
- Prevents:
  - `@everyone`
  - `@here`
  - Role mentions
  - User mentions

Enabled by default on:
- content
- username
- embed text


## Configuration Reference

The embed section allows you to **have a default structure**, so you do not need to build embeds manually for each message.

```json
{
  "client_id": "DISCORD_APP_ID",
  "details": "Default details",
  "state": "Default state",
  "large_image": "large",
  "small_image": "small",
  "large_text": "Large hover",
  "small_text": "Small hover",

  "webhook_url": "WEBHOOK_URL",

  "color": "#5865F2",
  "title": "Default title",
  "url": null,
  "author_name": "Author",
  "author_icon": null,
  "author_url": null,
  "thumbnail": null,
  "description": "Default description",
  "image": null,
  "footer_text": "Footer",
  "footer_icon": null
}
```

> All fields are optional, except those marked as required by Discord. If you do not want them, set them to `null`. The default embed structure ensures you have a working format out-of-the-box without needing to manually define every field each time.


---

## License

Free to use, modify and distribute.

## Credits

Made with ❤️ for Pokémon SDK & Ruby projects.
Inspired by Discord IPC & Webhook official APIs.


[<img src="docs/app-store.svg">](https://apps.apple.com/app/id6466745933)

# Moblin - IRL Streaming

A free iOS app for IRL streaming. Mainly targeting [Twitch](https://twitch.tv), but can
stream to [YouTube](https://youtube.com), [Kick](https://kick.com), [Facebook](https://facebook.com)
and [OBS Studio](https://obsproject.com) as well (and probably more).

<p>
    <img src="https://github.com/eerimoq/moblin/raw/main/docs/iphone15-pro-max-screenshot.png" width="62%" >
    <img src="https://github.com/eerimoq/moblin/raw/main/docs/watch-series-9-screenshot.png" width="17%" >
    <img src="https://github.com/eerimoq/moblin/raw/main/docs/watch-series-9-screenshot-chat.png" width="17%" >
</p>

Discord: https://discord.gg/nt3UwHqbMM

Github: https://github.com/eerimoq/moblin

TestFlight: https://testflight.apple.com/join/PDpxEaGh

# Features

## Main app

- Stream using RTMP, RTMPS, SRT or SRTLA to any platform that supports
  them.
- H.264/AVC and H.265/HEVC video codecs.
- Up to 4K resolution and 60 FPS.
- SRTLA.
  - Can use one cellular, one WiFi and multiple Ethernet connections
    simultaneously. Often called bonding.
  - Upload statistics per active connection.
- Twitch integration.
  - Number of viewers.
  - Chat.
    - Announcements.
    - /me styling.
  - Optional login.
    - Follow and subscribe alerts.
- Kick integration.
  - Number of viewers.
  - Chat.
- YouTube integration.
  - Chat.
- AfreecaTv integration.
  - Scuffed chat.
- Basic scenes.
  - Alerts widget.
    - Trigged by Twitch events and chat messages.
  - Image widget. Show an image on stream.
  - Text widget.
    - Any text.
    - Weather conditions.
    - Temperature.
    - Timer.
    - Country.
    - City.
    - Subtitles.
    - Local time.
    - Speed.
    - Altitude.
    - Distance. Reset manually.
    - Debug information.
  - Browser widget. Show a web page on stream.
  - Map widget with location.
  - QR code widget.
  - Scene widget.
- Back or front camera.
  - Front camera mirrored on screen for natural experience.
- Back, front, top, bottom or external mic.
  - Automatically changes to external mic when connected.
- Video stabilization.
- Zoom.
  - Pinch-to-zoom.
  - Configurable presets.
- Back camera lens selection.
- Record to disk (MP4-file).
  - Configurable bitrate, video codec and key frame interval.
- RTMP server/ingest as video source.
- SRT(LA) server/ingest as video source.
- Localization. Supports many languages, for example English, French,
  German, Spanish, Polish, Chinese (Simplified) and Swedish.
- Tap screen for manual focus.
  - Return to auto focus with long press.
- Stream connection status and uptime.
- OBS WebSocket (remote control)
  - See current scene, streaming state and recoring state.
  - Change scene.
  - Start and stop the stream.
  - Snapshot.
  - Audio levels.
  - Set audio sync.
- Make phone screen black by pressing a button.
- Supports UVC (USB-C) cameras on iPad.
- Basic support for Mac.
- Video effects.
  - Grayscale.
  - Movie. Paint top and bottom of 16:9 video black to look like
    2.35:1.
  - Seipa.
  - Noise reduction.
  - Random. A single effect that applies a random effect.
  - Triple. Show center of image three times. Experimental.
- Alerts styling.
  - Optional text to speech (TTS).
    - Many voices.
  - Text message colors, font weight, font design and more.
  - Select sound and image per alert.
  - Image placement relative to your face or scene.
- Chat styling.
  - Optional text to speech (TTS).
    - Optionally subscribers only.
    - Many voices.
    - Detect language per message.
  - Colors, background, border and bold.
  - Twitch, Kick, BTTV, FFZ and 7TV emotes.
  - Optionally animated emotes.
  - Optionally remove old messages.
  - Width and height.
  - Optional message timestamp.
- Color spaces (for devices that supports them).
  - sRGB.
  - P3 D65.
  - Apple Log.
- Bundled and custom 3D LUT effects.
  - Especially useful when using Apple Log.
- Battery indicator.
  - Charging icon.
  - Optionally with percentage.
- Web browser.
  - Only visible to the streamer.
- Game controllers for remote control.
  - Zoom in and out.
  - Change scene.
  - Torch.
  - Mute.
  - ...
- Cosmetics.
  - Select Moblin icon to show in app and on home screen.
  - Optionally purchase additional Moblin icons to support developers.
- Configure stream resolution, FPS, video codec, bitrate and more.
- Configurable bitrate presets.
- Adaptive bitrate for SRT(LA).
- Optionally remote control the streamer's Moblin app over the network.
  - Shows basic status information.
  - Change scene.
  - Change mic.
  - Change bitrate.
  - Change zoom.
  - Show logs.
- Torch.
- Mute audio.
- Deep link settings (moblin://).
  - Including a deep link creator for service providers.
- Landscape.
  - Both 0 and 180 degrees orientation. Video always with gravity down
    (never upside down).
- Portrait.
  - UI in portrait, but video in landscape. To be improved.
- Background streaming.
  - With audio.
  - Video will be a freezed frame as video cannot be captured in background.
- Simple poll.
  - Chat types 1, 2 or 3.
- Chat bot.
  - Turn chat text to speech on an off.
  - Fix OBS.
- Screen capture as video source.
- Basic video player as video source and mic.
- DJI camera Bluetooth controller.
  - Automatically start DJI camera live stream.
  - Tested with OA4, OA3 and OP3.

## Apple Watch companion app

- Stream preview.
- Show audio level.
- Show bitrate.
- Show iPhone/iPad thermal state.
- Chat.
  - Limited to 20 messages.
- Control.
  - Zoom using digital crown and presets.
  - Switch scene.
  - Go live.
  - Record.
  - Mute.
  - Skip current TTS message.
- Watch face complication.

# Ideas/plan

- Show two cameras at the same time.
- Audio filters. For example volume limiter.
  - An adjustable gain would be nice, then limiter (to keep audio from
    clipping), and a noise gate would be my top 3 requested audio
    filters when you have the time. I think that would be the same
    order in terms of complexity to implement as well.
- Add Twitch/Kick Icons next to chat messages depending on which
  platform the message came from.
- Lookup Twitch channel id from channel name. Possibly login to
  Twitch.

# Import settings using moblin:// (custom URL)

## Examples

### New stream

An example creating a new stream is

```
moblin://?{"streams":[{"name":"BELABOX%20UK","url":"srtla://uk.srt.belabox.net:5000?streamid=9812098rh9hf8942hid","video":{"codec":"H.265/HEVC"},"obs":{"webSocketUrl":"ws://123.22.32.112:5465","webSocketPassword":"foobar"}}]}
```

where the URL decoded pretty printed JSON blob is

``` json
{
  "streams": [
    {
      "name": "BELABOX UK",
      "url": "srtla://uk.srt.belabox.net:5000?streamid=9812098rh9hf8942hid",
      "video": {
        "codec": "H.265/HEVC"
      },
      "obs": {
        "webSocketUrl": "ws://123.22.32.112:5465",
        "webSocketPassword": "foobar"
      }
    }
  ]
}
```

### Quick button settings

An example with only two quick buttons enabled is

```
moblin://?{"quickButtons":{"twoColumns":false,"showName":true,"enableScroll":true,"disableAllButtons":true,"buttons":[{"type":"Mute","enabled":true},{"type":"Draw","enabled":true}]}}
```

where the URL decoded pretty printed JSON blob is

``` json
{
  "quickButtons": {
    "twoColumns": false,
    "showName": true,
    "enableScroll": true,
    "disableAllButtons": true,
    "buttons": [
      {
        "type": "Mute",
        "enabled": true
      },
      {
        "type": "Draw",
        "enabled": true
      }
    ]
  }
}
```

## Specification

Format: `moblin://?<URL encoded JSON blob>`

The `MoblinSettingsUrl` class in
[MoblinSettingsUrl.swift](https://github.com/eerimoq/moblin/blob/main/Moblin/Various/MoblinSettingsUrl.swift) defines
the JSON blob format. Class members are JSON object keys. Members with
`?` after the type are optional. Some types are defined in
[Settings.swift](https://github.com/eerimoq/moblin/blob/main/Moblin/Various/Settings.swift).

# Similar software

- https://irlpro.app/
- Twitch app.
- https://softvelum.com/larix/ios/

# Development environment setup

Roughly the steps to setup Moblin's developement environment.

1. Install Xcode with iOS and MacOS simulators on your Mac.

2. Open a terminal.

3. Clone Moblin.

   `git clone https://github.com/eerimoq/moblin.git`

4. Enter Moblins repository.

   `cd moblin`

5. Create an empty configuration file.

   `touch Config.xcconfig`

6. Open the Moblin project in Xcode. Wait for the dependencies to load.

   `open Moblin.xcodeproj`

7. Press `Command + B` to build Moblin.

8. Click on the code signing error and add your account. No Apple
   developer account is needed.

9. Change the `Bundle Identifier` to anything you want (i.e. `com.whoami.Moblin`).

10. Remove `In-App Purchase` and `Access Wi-Fi Information` by clicking
   their trash cans.

11. Build again. Hopefully successfully.

12. Enable developer mode in your iPhone/iPad.

13. Select you iPhone/iPad as `Run Destination` in Xcode (at the top
    in the middle).

14. Build and run by pressing `Command + R`.

14. Done!

<p align="center">
  <img src="logo.png" alt="capacitor-native-glass" width="180" />
</p>

<h1 align="center">Capacitor Native Glass</h1>

<p align="center">
  Real <strong>iOS 26 Liquid Glass</strong> surfaces for Capacitor apps —
  the native material, not a CSS imitation.
  <br />
  Native UIKit overlays over your WebView. SF Symbols. Auto-discovered.
</p>

<p align="center">
  <a href="https://www.npmjs.com/package/capacitor-native-glass"><img src="https://img.shields.io/npm/v/capacitor-native-glass.svg" alt="npm version" /></a>
  <a href="https://www.npmjs.com/package/capacitor-native-glass"><img src="https://img.shields.io/npm/dm/capacitor-native-glass.svg" alt="npm downloads" /></a>
  <a href="./LICENSE"><img src="https://img.shields.io/npm/l/capacitor-native-glass.svg" alt="license" /></a>
  <img src="https://img.shields.io/badge/capacitor-8-blue" alt="Capacitor 8" />
  <img src="https://img.shields.io/badge/iOS-26%2B-black" alt="iOS 26+" />
</p>

---

## Why?

The iOS 26 Liquid Glass effect is a **Metal/UIKit render** — dynamic refraction that
samples the content behind it. It **cannot be reproduced in CSS**. Web UI kits (`backdrop-filter:
blur`, etc.) only *imitate* the material: the components look plausible, but the "glass" gives
away that it's web.

The only real path in a Capacitor app is to render **genuine native views as overlays** on top
of the WebView and bridge their interactions back to JavaScript — the same technique native maps
and camera previews use. This plugin does exactly that, for the surfaces a content app actually
needs (bars, FAB, panel, mini-player, morphing).

## Features

- **Real Liquid Glass** — genuine `UIGlassEffect` / auto-glass UIKit views, not CSS
- **7 surfaces** — nav bar, toolbar, FAB, tinted interactive panel, native controls, morphing, mini-player
- **Morphing** — glass bubbles that converge and merge (`UIGlassContainerEffect`)
- **SF Symbols** — usable natively (impossible in the web layer)
- **Touch passthrough** — a `hitTest` host view lets taps reach the WebView outside the controls
- **Event bridge** — native taps surface in JS via `addListener('action', …)`
- **Auto-discovered** — SPM `Package.swift` + CocoaPods podspec, **zero Xcode setup**
- **Graceful fallback** — `UIBlurEffect` material below iOS 26
- **Capacitor 8**, TypeScript types included

## Demo

> Videos captured on a real iPhone (iOS 26). Real Liquid Glass only renders on device.

<!--
  GitHub does NOT render repo-committed .mp4 inline. To embed real video players:
  drag each file from ./media/ into a GitHub issue or the release notes, copy the
  resulting https://github.com/user-attachments/... URL, and paste it below in place
  of the screenshot links. Until then, the screenshots act as previews.
-->

<table>
  <tr>
    <td align="center"><img src="screenshots/morphing.png" width="220" /><br /><b>Morphing</b><br /><a href="media/morphing.mp4">▶ video</a></td>
    <td align="center"><img src="screenshots/mini-player.png" width="220" /><br /><b>Mini-player</b><br /><a href="media/mini-player.mp4">▶ video</a></td>
    <td align="center"><img src="screenshots/tab-bar.png" width="220" /><br /><b>Tab bar</b><br /><a href="media/tab-bar.mp4">▶ video</a></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots/native-controls.png" width="220" /><br /><b>Controls</b><br /><a href="media/native-controls.mp4">▶ video</a></td>
    <td align="center"><img src="screenshots/tinted-panel.png" width="220" /><br /><b>Tinted panel</b><br /><a href="media/tinted-panel.mp4">▶ video</a></td>
    <td align="center"><img src="screenshots/floating-button.png" width="220" /><br /><b>FAB</b><br /><a href="media/floating-button.mp4">▶ video</a></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots/toolbar.png" width="220" /><br /><b>Toolbar</b><br /><a href="media/toolbar.mp4">▶ video</a></td>
  </tr>
</table>

## Installation

```bash
npm install capacitor-native-glass
npx cap sync ios
```

No Xcode configuration needed — the plugin registers itself.

> **Requirements:** Capacitor ≥ 8, and **iOS 26 + Xcode 26** for real Liquid Glass.
> Older iOS falls back to a material blur.

## Quick Start

```ts
import { NativeGlass } from 'capacitor-native-glass'

// show native chrome
await NativeGlass.showNavbar({ title: 'MaBible' })
await NativeGlass.showToolbar({ items: ['Share', 'Favorite', 'Settings'] })
await NativeGlass.showMiniPlayer({ title: 'Now playing' })

// react to native taps
const sub = await NativeGlass.addListener('action', ({ id }) => {
  console.log('native action:', id) // "toolbar:Share", "segment:1", "miniplayer:playpause"…
})

// tear down
await NativeGlass.hideAll()
sub.remove()
```

## API

| Method | Renders |
|---|---|
| `showNavbar({ title })` | top `UINavigationBar` (auto-glass) |
| `showToolbar({ items })` | bottom `UIToolbar` (auto-glass) |
| `showFab({ systemIcon })` | floating `UIButton(.glass())` — `systemIcon` is an SF Symbol |
| `showPanel({ text })` | interactive, tinted `UIGlassEffect` panel |
| `showControls()` | native `UISegmentedControl` + `UISlider` + `UISearchBar` |
| `showMorphing()` | `UIGlassContainerEffect` — bubbles that merge & split |
| `showMiniPlayer({ title })` | floating glass "now playing" bar |
| `hideAll()` | removes every surface |
| `addListener('action', cb)` | native interaction events (`{ id }`) |

## Notes & limitations

- **Edge-anchored only.** Surfaces are fixed to screen edges; they don't scroll-sync with in-page
  DOM content (that jitters against WKWebView's async scrolling). Use them as chrome.
- **Touch passthrough** is handled by a transparent host view whose `hitTest` returns `nil`
  outside the actual controls, so the WebView keeps receiving taps.
- **iOS only.** On web/Android the methods reject with *"not implemented"*.

## License

MIT © imri-engineer

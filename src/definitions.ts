import type { PluginListenerHandle } from '@capacitor/core'

/** Emitted when the user interacts with a native surface. */
export interface NativeGlassActionEvent {
  /** Action identifier, e.g. `toolbar:Share`, `segment:1`, `miniplayer:playpause`. */
  id: string
}

/** A single glass surface identifier. */
export type GlassSurface =
  | 'toolbar'
  | 'navbar'
  | 'fab'
  | 'panel'
  | 'controls'
  | 'morphing'
  | 'miniPlayer'

export interface NativeGlassPlugin {
  /** Native bottom toolbar (automatic glass on iOS 26). */
  showToolbar(options: { items: string[] }): Promise<void>
  /** Native top navigation bar (automatic glass). */
  showNavbar(options: { title: string }): Promise<void>
  /** Floating action button (FAB) in Liquid Glass. `systemIcon` = SF Symbol name. */
  showFab(options: { systemIcon: string }): Promise<void>
  /** Floating interactive, tinted glass panel (UIGlassEffect). */
  showPanel(options: { text: string }): Promise<void>
  /** Native controls: segmented control + slider. */
  showControls(): Promise<void>
  /** Glass bubbles that converge and merge (UIGlassContainerEffect / morphing). */
  showMorphing(): Promise<void>
  /** Floating glass mini-player ("now playing" bar). */
  showMiniPlayer(options: { title: string }): Promise<void>
  /** Removes a single native surface, leaving the others untouched. */
  hide(options: { surface: GlassSurface }): Promise<void>
  /** Removes every native surface. */
  hideAll(): Promise<void>
  /** Listen to native interactions (taps on buttons/controls). */
  addListener(
    eventName: 'action',
    listener: (event: NativeGlassActionEvent) => void,
  ): Promise<PluginListenerHandle>
}

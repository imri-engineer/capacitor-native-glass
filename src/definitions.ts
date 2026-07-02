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

/** One entry of a native pull-down menu carried by a bar button. */
export interface GlassMenuItem {
  /** Identifier emitted in the `action` event as `menu:<id>`. Required for leaf items. */
  id?: string
  /** Visible label. */
  title: string
  /** SF Symbol name for the leading icon. */
  systemIcon?: string
  /** Render the item in red as a destructive action. */
  destructive?: boolean
  /** Grey the item out and block selection. */
  disabled?: boolean
  /** Show a checkmark. */
  checked?: boolean
  /** Nested submenu. */
  children?: GlassMenuItem[]
  /** For a submenu, render its children inline. */
  inline?: boolean
}

/**
 * A toolbar/navbar button. A plain string is a tap button that emits an
 * `action` event. An object with `menu` opens a NATIVE pull-down menu directly
 * on tap — anchored to the real bar button, no web overlay.
 */
export type GlassBarItem =
  | string
  | {
      /** Button label (used when no `systemIcon`). */
      title?: string
      /** SF Symbol for the button itself. */
      systemIcon?: string
      /** Identifier emitted as `toolbar:<id>` when tapped (menu-less buttons). */
      id?: string
      /** When set, tapping the button opens this native pull-down menu. */
      menu?: GlassMenuItem[]
    }

export interface NativeGlassPlugin {
  /**
   * Native bottom toolbar (automatic glass on iOS 26). Items may be plain
   * strings or objects carrying a native `menu` that opens on tap.
   */
  showToolbar(options: { items: GlassBarItem[] }): Promise<void>
  /**
   * Native top navigation bar (automatic glass). Optionally give the right
   * bar button a native pull-down `menu` that opens on tap.
   */
  showNavbar(options: { title: string; menu?: GlassMenuItem[] }): Promise<void>
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

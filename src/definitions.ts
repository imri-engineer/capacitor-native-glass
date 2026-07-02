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
   * Native top navigation bar (automatic glass). Give the right side either a
   * single pull-down `menu` (ellipsis button) or an explicit list of `items`.
   */
  showNavbar(options: {
    title: string
    menu?: GlassMenuItem[]
    items?: GlassBarItem[]
    /**
     * Multiple trailing button groups, each rendered as its OWN glass capsule
     * on iOS 26 (e.g. `[[done], [edit, more]]`). Takes precedence over `items`.
     */
    groups?: GlassBarItem[][]
  }): Promise<void>
  /**
   * Change the nav bar's trailing side IN PLACE (no recreation) with an
   * animated transition — on iOS 26 the Liquid Glass morphs between states,
   * including SPLITTING one glass capsule into several (like Apple Notes:
   * `[•••]` becoming `[✓] [edit ⋯]`) when you pass `groups`.
   */
  updateNavbar(options: {
    menu?: GlassMenuItem[]
    items?: GlassBarItem[]
    groups?: GlassBarItem[][]
  }): Promise<void>
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
  /**
   * Attach a native context menu (`UIContextMenuInteraction`) to a region of
   * the WebView. `longPress` (default) lifts a preview above a blurred
   * background; `tap` opens a pull-down immediately. Selection emits an
   * `action` event `menu:<id>`. Stays until `detachMenu`/`detachAllMenus`.
   */
  attachMenu(options: ContextMenuAttachOptions): Promise<void>
  /** Update the rect of an attached menu (after scroll/resize). */
  updateMenuRect(options: { id: string; rect: ContextMenuRect }): Promise<void>
  /** Remove a single attached menu. */
  detachMenu(options: { id: string }): Promise<void>
  /** Remove every attached menu. */
  detachAllMenus(): Promise<void>
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

/** A rectangle in CSS/screen points (as from `getBoundingClientRect()`). */
export interface ContextMenuRect {
  x: number
  y: number
  width: number
  height: number
}

/** How a context menu opens. */
export type ContextMenuTrigger = 'longPress' | 'tap'

export interface ContextMenuAttachOptions {
  /** Stable id used to `detachMenu` later. */
  id: string
  /** The trigger region (in CSS points). */
  rect: ContextMenuRect
  /** Menu contents (same shape as bar-button menus). */
  items: GlassMenuItem[]
  /** Optional menu title header. */
  title?: string
  /** `longPress` (default, with lifted preview) or `tap` (pull-down). */
  trigger?: ContextMenuTrigger
  /**
   * Optional base64 PNG (no `data:` prefix) of the element, used as the lifted
   * preview on long-press (capture with html2canvas). Without it, iOS lifts a
   * plain rounded rectangle of the rect.
   */
  previewImage?: string
  /** Corner radius (points) for the lifted preview. Default 12. */
  previewCornerRadius?: number
}

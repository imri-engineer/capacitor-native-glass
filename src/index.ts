import { registerPlugin } from '@capacitor/core'

import type { NativeGlassPlugin } from './definitions'

/**
 * NativeGlass — native iOS 26 Liquid Glass surfaces rendered as overlays above
 * the WebView. Auto-discovered by Capacitor (CAP_PLUGIN bridge on iOS).
 * On web/Android the methods are no-ops (reject with "not implemented").
 */
const NativeGlass = registerPlugin<NativeGlassPlugin>('NativeGlass')

export * from './definitions'
export { NativeGlass }

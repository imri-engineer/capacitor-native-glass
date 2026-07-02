import Foundation
import Capacitor
import UIKit

/**
 * NativeGlass — expose plusieurs surfaces Liquid Glass NATIVES (iOS 26) en
 * overlays above the WebView: bottom toolbar, top nav bar, FAB, glass panel.
 *
 * Glass is AUTOMATIC for standard UIKit components (toolbar/navbar) once built
 * with the iOS 26 SDK. For the FAB and the custom panel we use the explicit
 * utilise l'API explicite UIGlassEffect (iOS 26+), avec fallback material.
 *
 * Each overlay is edge-anchored (fixed) → no scroll sync; hit-testing lets
 * touches pass through to the WebView elsewhere.
 */
@objc(NativeGlassPlugin)
public class NativeGlassPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "NativeGlassPlugin"
    public let jsName = "NativeGlass"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "showToolbar", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "showNavbar", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "showFab", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "showPanel", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "showControls", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "showMorphing", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "showMiniPlayer", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "hide", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "hideAll", returnType: CAPPluginReturnPromise),
    ]

    private var host: GlassHostView?

    private func ensureHost() -> GlassHostView? {
        guard let bridgeView = self.bridge?.viewController?.view else { return nil }
        if host == nil {
            let h = GlassHostView(frame: bridgeView.bounds)
            h.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            h.backgroundColor = .clear
            bridgeView.addSubview(h)
            host = h
        }
        // forward native control actions to JS
        host?.onAction = { [weak self] id in
            self?.notifyListeners("action", data: ["id": id])
        }
        return host
    }

    @objc func showToolbar(_ call: CAPPluginCall) {
        let raw = call.getArray("items") ?? ["Share", "Favorite", "Settings"]
        let items = raw.map { GlassBarItem(from: $0) }
        DispatchQueue.main.async {
            self.ensureHost()?.showToolbar(items: items)
            call.resolve()
        }
    }

    @objc func showNavbar(_ call: CAPPluginCall) {
        let title = call.getString("title") ?? "MaBible"
        let menu = (call.getArray("menu") as? [[String: Any]])
        DispatchQueue.main.async {
            self.ensureHost()?.showNavbar(title: title, menu: menu)
            call.resolve()
        }
    }

    @objc func showFab(_ call: CAPPluginCall) {
        let symbol = call.getString("systemIcon") ?? "plus"
        DispatchQueue.main.async {
            self.ensureHost()?.showFab(symbol: symbol)
            call.resolve()
        }
    }

    @objc func showPanel(_ call: CAPPluginCall) {
        let text = call.getString("text") ?? "Panneau Liquid Glass natif"
        DispatchQueue.main.async {
            self.ensureHost()?.showPanel(text: text)
            call.resolve()
        }
    }

    @objc func showControls(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.ensureHost()?.showControls()
            call.resolve()
        }
    }

    @objc func showMorphing(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.ensureHost()?.showMorphing()
            call.resolve()
        }
    }

    @objc func showMiniPlayer(_ call: CAPPluginCall) {
        let title = call.getString("title") ?? "Sermon en cours"
        DispatchQueue.main.async {
            self.ensureHost()?.showMiniPlayer(title: title)
            call.resolve()
        }
    }

    @objc func hide(_ call: CAPPluginCall) {
        guard let surface = call.getString("surface") else {
            call.reject("Missing 'surface'")
            return
        }
        DispatchQueue.main.async {
            self.host?.hide(surface: surface)
            call.resolve()
        }
    }

    @objc func hideAll(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.host?.hideAll()
            call.resolve()
        }
    }
}

/**
 * Transparent host view covering the screen. hitTest lets touches pass to the
 * WebView everywhere EXCEPT on the actual glass controls.
 */
final class GlassHostView: UIView {
    var onAction: ((String) -> Void)?

    private var toolbar: UIToolbar?
    private var navbar: UINavigationBar?
    private var fab: UIButton?
    private var panel: UIVisualEffectView?
    private var controls: UIStackView?
    private var morphing: UIVisualEffectView?
    private var miniPlayer: UIVisualEffectView?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        // transparent → pass to WebView; a control → intercept it
        return hit === self ? nil : hit
    }

    // MARK: Bottom toolbar (auto-glass iOS 26)
    func showToolbar(items: [GlassBarItem]) {
        toolbar?.removeFromSuperview()
        let tb = UIToolbar()
        tb.translatesAutoresizingMaskIntoConstraints = false
        var bar: [UIBarButtonItem] = []
        for item in items {
            bar.append(makeBarButton(item))
            bar.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        }
        if !bar.isEmpty { bar.removeLast() }
        tb.items = bar
        addSubview(tb)
        NSLayoutConstraint.activate([
            tb.leadingAnchor.constraint(equalTo: leadingAnchor),
            tb.trailingAnchor.constraint(equalTo: trailingAnchor),
            tb.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
        ])
        toolbar = tb
    }

    /// Build a bar button. If the item carries a `menu`, the button opens a
    /// native pull-down on tap; otherwise it emits a `toolbar:<id>` action.
    private func makeBarButton(_ item: GlassBarItem) -> UIBarButtonItem {
        let image = item.systemIcon.flatMap { UIImage(systemName: $0) }
        if let menuItems = item.menu {
            let menu = GlassMenuBuilder.menu(from: menuItems) { [weak self] id in
                self?.onAction?("menu:\(id)")
            }
            // Build then assign .menu (iOS 14+) to stay below the iOS 16
            // `init(...:menu:)` convenience initializer.
            let btn: UIBarButtonItem
            if let image = image {
                btn = UIBarButtonItem(image: image, style: .plain, target: nil, action: nil)
            } else {
                btn = UIBarButtonItem(title: item.title, style: .plain, target: nil, action: nil)
            }
            btn.menu = menu
            return btn
        }
        let btn: UIBarButtonItem
        if let image = image {
            btn = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(toolbarTap(_:)))
        } else {
            btn = UIBarButtonItem(title: item.title, style: .plain, target: self, action: #selector(toolbarTap(_:)))
        }
        btn.accessibilityIdentifier = item.id ?? item.title
        return btn
    }

    @objc private func toolbarTap(_ item: UIBarButtonItem) {
        onAction?("toolbar:\(item.accessibilityIdentifier ?? item.title ?? "")")
    }

    // MARK: Top nav bar (auto-glass iOS 26)
    func showNavbar(title: String, menu: [[String: Any]]?) {
        navbar?.removeFromSuperview()
        let nb = UINavigationBar()
        nb.translatesAutoresizingMaskIntoConstraints = false
        let navItem = UINavigationItem(title: title)
        if let menuItems = menu {
            let m = GlassMenuBuilder.menu(from: menuItems) { [weak self] id in
                self?.onAction?("menu:\(id)")
            }
            let btn = UIBarButtonItem(
                image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: nil, action: nil)
            btn.menu = m
            navItem.rightBarButtonItem = btn
        } else {
            navItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .action, target: self, action: #selector(navTap))
        }
        nb.items = [navItem]
        addSubview(nb)
        NSLayoutConstraint.activate([
            nb.leadingAnchor.constraint(equalTo: leadingAnchor),
            nb.trailingAnchor.constraint(equalTo: trailingAnchor),
            nb.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
        ])
        navbar = nb
    }
    @objc private func navTap() { onAction?("navbar:action") }

    // MARK: FAB (UIGlassEffect explicite, iOS 26)
    func showFab(symbol: String) {
        fab?.removeFromSuperview()
        var cfg: UIButton.Configuration
        if #available(iOS 26.0, *) {
            cfg = .glass()
        } else {
            cfg = .filled()
        }
        cfg.image = UIImage(systemName: symbol)
        cfg.cornerStyle = .capsule
        let b = UIButton(configuration: cfg)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(fabTap), for: .touchUpInside)
        addSubview(b)
        NSLayoutConstraint.activate([
            b.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
            b.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -96),
            b.widthAnchor.constraint(equalToConstant: 60),
            b.heightAnchor.constraint(equalToConstant: 60),
        ])
        fab = b
    }
    @objc private func fabTap() { onAction?("fab") }

    // MARK: Custom glass panel (UIGlassEffect / material fallback)
    func showPanel(text: String) {
        panel?.removeFromSuperview()
        let effect: UIVisualEffect
        if #available(iOS 26.0, *) {
            let g = UIGlassEffect(style: .regular)
            g.isInteractive = true          // reacts to touch
            g.tintColor = UIColor.systemPurple.withAlphaComponent(0.5)  // tinted glass
            effect = g
        } else {
            effect = UIBlurEffect(style: .systemMaterial)
        }
        let v = UIVisualEffectView(effect: effect)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 22
        v.clipsToBounds = true

        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        v.contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: v.contentView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: v.contentView.trailingAnchor, constant: -16),
            label.centerYAnchor.constraint(equalTo: v.contentView.centerYAnchor),
        ])

        addSubview(v)
        NSLayoutConstraint.activate([
            v.centerXAnchor.constraint(equalTo: centerXAnchor),
            v.centerYAnchor.constraint(equalTo: centerYAnchor),
            v.widthAnchor.constraint(equalToConstant: 260),
            v.heightAnchor.constraint(equalToConstant: 120),
        ])
        panel = v
    }

    // MARK: Native controls (auto-glass iOS 26) — segmented + slider
    func showControls() {
        controls?.removeFromSuperview()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        let seg = UISegmentedControl(items: ["Read", "Audio", "Video"])
        seg.selectedSegmentIndex = 0
        seg.addTarget(self, action: #selector(segChanged(_:)), for: .valueChanged)

        let slider = UISlider()
        slider.value = 0.4
        slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)

        [seg, slider].forEach { stack.addArrangedSubview($0) }
        addSubview(stack)
        // centrés (le centre de l'écran est libre : la légende est dans le header web)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        controls = stack
    }
    @objc private func segChanged(_ s: UISegmentedControl) { onAction?("segment:\(s.selectedSegmentIndex)") }
    @objc private func sliderChanged(_ s: UISlider) { onAction?("slider:\(String(format: "%.2f", s.value))") }

    // MARK: Morphing (UIGlassContainerEffect — glass bubbles that merge)
    func showMorphing() {
        morphing?.removeFromSuperview()
        let effect: UIVisualEffect
        if #available(iOS 26.0, *) {
            let c = UIGlassContainerEffect()
            c.spacing = 24 // distance at which bubbles start merging
            effect = c
        } else {
            effect = UIBlurEffect(style: .systemThinMaterial)
        }
        let container = UIVisualEffectView(effect: effect)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.frame = CGRect(x: 0, y: 0, width: 260, height: 130)

        // 3 glass bubbles — spread out, then animated toward the center
        // (overlapping within `spacing`) → glass fusion/morphing.
        var bubbles: [UIVisualEffectView] = []
        let icons = ["🕮", "🎧", "✝︎"]
        let spread: [CGFloat] = [45, 130, 215] // spread-out X positions (start)
        for i in 0..<3 {
            let bubbleEffect: UIVisualEffect
            if #available(iOS 26.0, *) {
                bubbleEffect = UIGlassEffect(style: .regular)
            } else {
                bubbleEffect = UIBlurEffect(style: .systemMaterial)
            }
            let bubble = UIVisualEffectView(effect: bubbleEffect)
            bubble.frame = CGRect(x: spread[i] - 38, y: 27, width: 76, height: 76)
            bubble.layer.cornerRadius = 38
            bubble.clipsToBounds = true
            let l = UILabel(frame: bubble.bounds)
            l.text = icons[i]
            l.textAlignment = .center
            l.font = .systemFont(ofSize: 30)
            bubble.contentView.addSubview(l)
            container.contentView.addSubview(bubble)
            bubbles.append(bubble)
        }

        addSubview(container)
        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: centerXAnchor),
            container.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 60),
            container.widthAnchor.constraint(equalToConstant: 260),
            container.heightAnchor.constraint(equalToConstant: 130),
        ])
        morphing = container

        // animate the 3 bubbles to the CENTER (overlapping → glass fuses),
        // then spread them back (auto-reverse) → visible morphing.
        UIView.animate(
            withDuration: 1.6, delay: 0.3,
            options: [.autoreverse, .repeat, .curveEaseInOut]
        ) {
            for b in bubbles {
                b.center = CGPoint(x: 130, y: 65) // all centered → fusion
            }
        }
    }

    // MARK: Native mini-player (floating glass bar)
    func showMiniPlayer(title: String) {
        miniPlayer?.removeFromSuperview()
        let effect: UIVisualEffect
        if #available(iOS 26.0, *) {
            effect = UIGlassEffect(style: .regular)
        } else {
            effect = UIBlurEffect(style: .systemMaterial)
        }
        let bar = UIVisualEffectView(effect: effect)
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.layer.cornerRadius = 16
        bar.clipsToBounds = true

        // artwork (pochette) — dégradé arrondi
        let artwork = UIView()
        artwork.translatesAutoresizingMaskIntoConstraints = false
        artwork.layer.cornerRadius = 8
        artwork.clipsToBounds = true
        let grad = CAGradientLayer()
        grad.colors = [UIColor.systemPurple.cgColor, UIColor.systemPink.cgColor]
        grad.startPoint = CGPoint(x: 0, y: 0)
        grad.endPoint = CGPoint(x: 1, y: 1)
        grad.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        artwork.layer.addSublayer(grad)

        // titre + sous-titre
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        let subtitle = UILabel()
        subtitle.text = "Episode 12 · 12:04"
        subtitle.font = .systemFont(ofSize: 12)
        subtitle.textColor = .secondaryLabel
        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitle])
        textStack.axis = .vertical
        textStack.spacing = 1
        textStack.translatesAutoresizingMaskIntoConstraints = false

        // boutons prev / play-pause / next
        func ctrl(_ symbol: String, _ action: Selector) -> UIButton {
            let b = UIButton(type: .system)
            b.setImage(UIImage(systemName: symbol), for: .normal)
            b.tintColor = .label
            b.addTarget(self, action: action, for: .touchUpInside)
            b.translatesAutoresizingMaskIntoConstraints = false
            return b
        }
        let prev = ctrl("backward.fill", #selector(miniPrev))
        let play = ctrl("pause.fill", #selector(miniTap))
        let next = ctrl("forward.fill", #selector(miniNext))
        let btnStack = UIStackView(arrangedSubviews: [prev, play, next])
        btnStack.axis = .horizontal
        btnStack.spacing = 18
        btnStack.translatesAutoresizingMaskIntoConstraints = false

        bar.contentView.addSubview(artwork)
        bar.contentView.addSubview(textStack)
        bar.contentView.addSubview(btnStack)
        addSubview(bar)
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            bar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            bar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -12),
            bar.heightAnchor.constraint(equalToConstant: 64),
            artwork.leadingAnchor.constraint(equalTo: bar.contentView.leadingAnchor, constant: 10),
            artwork.centerYAnchor.constraint(equalTo: bar.contentView.centerYAnchor),
            artwork.widthAnchor.constraint(equalToConstant: 44),
            artwork.heightAnchor.constraint(equalToConstant: 44),
            textStack.leadingAnchor.constraint(equalTo: artwork.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: bar.contentView.centerYAnchor),
            btnStack.leadingAnchor.constraint(greaterThanOrEqualTo: textStack.trailingAnchor, constant: 8),
            btnStack.trailingAnchor.constraint(equalTo: bar.contentView.trailingAnchor, constant: -16),
            btnStack.centerYAnchor.constraint(equalTo: bar.contentView.centerYAnchor),
        ])
        miniPlayer = bar
    }
    @objc private func miniTap() { onAction?("miniplayer:playpause") }
    @objc private func miniPrev() { onAction?("miniplayer:prev") }
    @objc private func miniNext() { onAction?("miniplayer:next") }

    func hideAll() {
        [toolbar, navbar, fab, panel, controls, morphing, miniPlayer].forEach { $0?.removeFromSuperview() }
        toolbar = nil; navbar = nil; fab = nil; panel = nil
        controls = nil; morphing = nil; miniPlayer = nil
    }

    /// Remove a single surface by id, leaving the others untouched.
    func hide(surface: String) {
        switch surface {
        case "toolbar":    toolbar?.removeFromSuperview();    toolbar = nil
        case "navbar":     navbar?.removeFromSuperview();     navbar = nil
        case "fab":        fab?.removeFromSuperview();        fab = nil
        case "panel":      panel?.removeFromSuperview();      panel = nil
        case "controls":   controls?.removeFromSuperview();   controls = nil
        case "morphing":   morphing?.removeFromSuperview();   morphing = nil
        case "miniPlayer": miniPlayer?.removeFromSuperview(); miniPlayer = nil
        default: break
        }
    }
}

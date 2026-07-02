import UIKit

/**
 * Transparent overlay placed on the WebView. Each attached region is a
 * `MenuTriggerView` carrying a `UIContextMenuInteraction`. The host forwards
 * normal touches to the WebView and only claims a touch inside a trigger, where
 * a long-press raises a native menu with a lifted preview (or a tap opens a
 * pull-down). Menu trees are built by the shared `GlassMenuBuilder`.
 */
final class ContextMenuHostView: UIView {
    /// Called with the selected leaf item's id.
    var onSelect: ((String) -> Void)?

    private var triggers: [String: MenuTriggerView] = [:]

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for trigger in triggers.values where trigger.frame.contains(point) {
            return trigger
        }
        return nil
    }

    func attach(
        id: String,
        rect: CGRect,
        items: [[String: Any]],
        title: String?,
        previewImage: UIImage?,
        cornerRadius: CGFloat,
        tapTrigger: Bool
    ) {
        triggers[id]?.removeFromSuperview()
        let trigger = MenuTriggerView(frame: rect)
        trigger.items = items
        trigger.menuTitle = title
        trigger.previewImage = previewImage
        trigger.previewCornerRadius = cornerRadius
        trigger.onSelect = onSelect
        trigger.configure(tapTrigger: tapTrigger)
        addSubview(trigger)
        triggers[id] = trigger
    }

    func updateRect(id: String, rect: CGRect) {
        triggers[id]?.frame = rect
    }

    func detach(id: String) {
        triggers[id]?.removeFromSuperview()
        triggers[id] = nil
    }

    func detachAll() {
        triggers.values.forEach { $0.removeFromSuperview() }
        triggers.removeAll()
    }
}

/// One transparent region owning a `UIContextMenuInteraction`.
final class MenuTriggerView: UIView, UIContextMenuInteractionDelegate {
    var menuTitle: String?
    var items: [[String: Any]] = []
    var previewImage: UIImage?
    var previewCornerRadius: CGFloat = 12
    var onSelect: ((String) -> Void)?

    private lazy var previewView: UIImageView = {
        let iv = UIImageView(frame: bounds)
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = false
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(tapTrigger: Bool) {
        if tapTrigger {
            let button = UIButton(type: .system)
            button.frame = bounds
            button.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            button.backgroundColor = .clear
            if #available(iOS 14.0, *) {
                button.showsMenuAsPrimaryAction = true
                button.menu = buildMenu()
            }
            addSubview(button)
        } else {
            addInteraction(UIContextMenuInteraction(delegate: self))
        }
    }

    // MARK: UIContextMenuInteractionDelegate

    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            self?.buildMenu()
        }
    }

    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        targetedPreview()
    }

    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        previewForDismissingMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        targetedPreview()
    }

    private func targetedPreview() -> UITargetedPreview? {
        // nil → iOS lifts the trigger view itself, so the menu always opens.
        guard let image = previewImage, image.size.width > 0, image.size.height > 0 else {
            return nil
        }
        previewView.image = image
        previewView.frame = bounds
        previewView.layer.cornerRadius = previewCornerRadius
        if previewView.superview == nil { insertSubview(previewView, at: 0) }
        let params = UIPreviewParameters()
        params.backgroundColor = .clear
        params.visiblePath = UIBezierPath(roundedRect: bounds, cornerRadius: previewCornerRadius)
        return UITargetedPreview(view: previewView, parameters: params)
    }

    private func buildMenu() -> UIMenu {
        // Reuse the shared builder used by toolbar/navbar bar-button menus.
        GlassMenuBuilder.menu(from: items, title: menuTitle ?? "") { [weak self] id in
            self?.onSelect?(id)
        }
    }
}

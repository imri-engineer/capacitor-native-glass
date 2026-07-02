import UIKit

/// A parsed toolbar/navbar item: either a plain tap button or one carrying a
/// native pull-down menu that opens on tap.
struct GlassBarItem {
    var title: String
    var systemIcon: String?
    var id: String?
    var menu: [[String: Any]]?

    init(from value: Any) {
        if let s = value as? String {
            title = s
            id = s
        } else if let d = value as? [String: Any] {
            title = d["title"] as? String ?? ""
            systemIcon = d["systemIcon"] as? String
            id = d["id"] as? String ?? (d["title"] as? String)
            menu = d["menu"] as? [[String: Any]]
        } else {
            title = ""
        }
    }
}

/// Builds a `UIMenu` tree from the JSON item array shared by toolbar/navbar
/// buttons. `onSelect` is called with the leaf item's `id`.
enum GlassMenuBuilder {
    static func menu(
        from items: [[String: Any]],
        title: String = "",
        onSelect: @escaping (String) -> Void
    ) -> UIMenu {
        UIMenu(title: title, children: items.map { element(from: $0, onSelect: onSelect) })
    }

    private static func element(from dict: [String: Any], onSelect: @escaping (String) -> Void) -> UIMenuElement {
        let title = dict["title"] as? String ?? ""
        let image = (dict["systemIcon"] as? String).flatMap { UIImage(systemName: $0) }

        if let children = dict["children"] as? [[String: Any]] {
            var options: UIMenu.Options = []
            if dict["inline"] as? Bool == true { options.insert(.displayInline) }
            return UIMenu(
                title: title,
                image: image,
                options: options,
                children: children.map { element(from: $0, onSelect: onSelect) }
            )
        }

        let id = dict["id"] as? String ?? ""
        var attributes: UIAction.Attributes = []
        if dict["destructive"] as? Bool == true { attributes.insert(.destructive) }
        if dict["disabled"] as? Bool == true { attributes.insert(.disabled) }
        let state: UIMenuElement.State = (dict["checked"] as? Bool == true) ? .on : .off

        return UIAction(title: title, image: image, attributes: attributes, state: state) { _ in
            onSelect(id)
        }
    }
}

import Foundation
import UIKit

// MARK: - Declarative model

final class TeleFlowRow {
    enum Kind {
        case link(icon: String?, color: UIColor?, value: () -> String?, action: (UIViewController) -> Void)
        case toggle(icon: String?, color: UIColor?, get: () -> Bool, set: (Bool) -> Void)
        case choice(isSelected: () -> Bool, action: () -> Void)
        case button(isDestructive: Bool, action: (UIViewController) -> Void)
    }

    let title: String
    let kind: Kind

    init(title: String, kind: Kind) {
        self.title = title
        self.kind = kind
    }
}

final class TeleFlowSection {
    let header: String?
    let footer: String?
    let rows: [TeleFlowRow]

    init(header: String? = nil, footer: String? = nil, rows: [TeleFlowRow]) {
        self.header = header
        self.footer = footer
        self.rows = rows
    }
}

// MARK: - Generic list screen

final class TeleFlowListController: UITableViewController {
    private let makeSections: () -> [TeleFlowSection]
    private var sections: [TeleFlowSection] = []

    init(title: String, sections: @escaping () -> [TeleFlowSection]) {
        self.makeSections = sections
        super.init(style: .insetGrouped)
        self.title = title
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.overrideUserInterfaceStyle = .dark
        self.tableView.backgroundColor = .black
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.reload()
    }

    func reload() {
        self.sections = self.makeSections()
        self.tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sections[section].header?.uppercased()
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return self.sections[section].footer
    }

    private static func iconImage(symbol: String, color: UIColor) -> UIImage {
        let size = CGSize(width: 30.0, height: 30.0)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            color.setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 7.0).fill()
            let configuration = UIImage.SymbolConfiguration(pointSize: 15.0, weight: .semibold)
            if let symbolImage = UIImage(systemName: symbol, withConfiguration: configuration)?.withTintColor(.white, renderingMode: .alwaysOriginal) {
                let symbolSize = symbolImage.size
                symbolImage.draw(in: CGRect(x: (size.width - symbolSize.width) / 2.0, y: (size.height - symbolSize.height) / 2.0, width: symbolSize.width, height: symbolSize.height))
            }
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = self.sections[indexPath.section].rows[indexPath.row]
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.backgroundColor = UIColor(white: 0.11, alpha: 1.0)
        cell.textLabel?.text = row.title
        cell.textLabel?.textColor = .white
        cell.selectionStyle = .default

        switch row.kind {
        case let .link(icon, color, value, _):
            if let icon = icon, let color = color {
                cell.imageView?.image = TeleFlowListController.iconImage(symbol: icon, color: color)
            }
            cell.detailTextLabel?.text = value()
            cell.accessoryType = .disclosureIndicator
        case let .toggle(icon, color, get, _):
            if let icon = icon, let color = color {
                cell.imageView?.image = TeleFlowListController.iconImage(symbol: icon, color: color)
            }
            let toggle = UISwitch()
            toggle.isOn = get()
            toggle.tag = indexPath.section * 1000 + indexPath.row
            toggle.addTarget(self, action: #selector(self.toggleChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            cell.selectionStyle = .none
        case let .choice(isSelected, _):
            cell.accessoryType = isSelected() ? .checkmark : .none
        case let .button(isDestructive, _):
            cell.textLabel?.textColor = isDestructive ? .systemRed : .systemBlue
        }
        return cell
    }

    @objc private func toggleChanged(_ sender: UISwitch) {
        let section = sender.tag / 1000
        let rowIndex = sender.tag % 1000
        guard section < self.sections.count, rowIndex < self.sections[section].rows.count else {
            return
        }
        if case let .toggle(_, _, _, set) = self.sections[section].rows[rowIndex].kind {
            set(sender.isOn)
        }
        self.reload()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = self.sections[indexPath.section].rows[indexPath.row]
        switch row.kind {
        case let .link(_, _, _, action):
            action(self)
        case .toggle:
            break
        case let .choice(_, action):
            action()
            self.reload()
        case let .button(_, action):
            action(self)
        }
    }
}

// MARK: - Screens

public enum TeleFlowMenu {
    public static func makeController() -> UIViewController {
        let root = TeleFlowListController(title: "KinopoiskGram", sections: {
            return [
                TeleFlowSection(rows: [
                    TeleFlowRow(title: "Сообщения и история", kind: .link(icon: "envelope.fill", color: .systemBlue, value: { nil }, action: { controller in
                        controller.navigationController?.pushViewController(TeleFlowMenu.makeMessagesController(), animated: true)
                    })),
                    TeleFlowRow(title: "Ghost", kind: .link(icon: "eye.slash.fill", color: .systemIndigo, value: { nil }, action: { controller in
                        controller.navigationController?.pushViewController(TeleFlowMenu.makeGhostController(), animated: true)
                    })),
                    TeleFlowRow(title: "Удалённые сообщения", kind: .link(icon: "trash.fill", color: .systemRed, value: {
                        return "\(TeleFlowDeletedStore.shared.count)"
                    }, action: { controller in
                        controller.navigationController?.pushViewController(TeleFlowMenu.makeDeletedController(), animated: true)
                    })),
                    TeleFlowRow(title: "Другое", kind: .link(icon: "slider.horizontal.3", color: .systemGray, value: { nil }, action: { controller in
                        controller.navigationController?.pushViewController(TeleFlowMenu.makeOtherController(), animated: true)
                    })),
                    TeleFlowRow(title: "Локальные звёзды", kind: .link(icon: "star.fill", color: .systemYellow, value: {
                        return TeleFlowSettings.shared.localStarsEnabled ? "\(TeleFlowSettings.shared.localStarsValue)" : nil
                    }, action: { controller in
                        controller.navigationController?.pushViewController(TeleFlowMenu.makeLocalStarsController(), animated: true)
                    }))
                ])
            ]
        })
        let navigationController = UINavigationController(rootViewController: root)
        navigationController.overrideUserInterfaceStyle = .dark
        navigationController.navigationBar.prefersLargeTitles = false
        root.navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: UIAction { [weak navigationController] _ in
            navigationController?.dismiss(animated: true)
        })
        return navigationController
    }

    static func makeMessagesController() -> UIViewController {
        let settings = TeleFlowSettings.shared
        return TeleFlowListController(title: "Сообщения и история", sections: {
            return [
                TeleFlowSection(header: "Сообщения", footer: "Если собеседник удалит сообщение, оно останется у тебя с пометкой. В исключённых чатах сообщения удаляются как обычно.", rows: [
                    TeleFlowRow(title: "Сохранять удалённые сообщения", kind: .toggle(icon: nil, color: nil, get: { settings.saveDeletedMessages }, set: { settings.saveDeletedMessages = $0 })),
                    TeleFlowRow(title: "Настроить удалённые сообщения", kind: .link(icon: nil, color: nil, value: { nil }, action: { controller in
                        controller.navigationController?.pushViewController(TeleFlowMenu.makeDeletedController(), animated: true)
                    }))
                ])
            ]
        })
    }

    static func makeDeletedController() -> UIViewController {
        let settings = TeleFlowSettings.shared
        let icons = ["🗑", "✏️", "🙈", "🔥", "⭐️", "⚡️", "❌"]
        return TeleFlowListController(title: "Deleted Messages", sections: {
            var iconRows: [TeleFlowRow] = icons.map { icon in
                return TeleFlowRow(title: icon, kind: .choice(isSelected: { settings.deletedIcon == icon }, action: { settings.deletedIcon = icon }))
            }
            let currentIcon = settings.deletedIcon
            iconRows.append(TeleFlowRow(title: "Свой символ / эмодзи", kind: .link(icon: nil, color: nil, value: { icons.contains(currentIcon) ? nil : currentIcon }, action: { controller in
                let alert = UIAlertController(title: "Свой символ", message: "Введи символ или эмодзи", preferredStyle: .alert)
                alert.addTextField { textField in
                    textField.text = settings.deletedIcon
                }
                alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
                alert.addAction(UIAlertAction(title: "Готово", style: .default, handler: { [weak alert, weak controller] _ in
                    if let text = alert?.textFields?.first?.text, !text.isEmpty {
                        settings.deletedIcon = String(text.prefix(4))
                    }
                    (controller as? TeleFlowListController)?.reload()
                }))
                controller.present(alert, animated: true)
            })))
            return [
                TeleFlowSection(header: "Icon", footer: "Показывается рядом со временем удалённого сообщения.", rows: iconRows),
                TeleFlowSection(header: "Exclusions", footer: "В исключённых чатах сообщения удаляются как обычно.", rows: [
                    TeleFlowRow(title: "Секретные чаты", kind: .toggle(icon: "lock.fill", color: .systemGray, get: { settings.deletedExcludeSecret }, set: { settings.deletedExcludeSecret = $0 })),
                    TeleFlowRow(title: "Личные чаты", kind: .toggle(icon: "person.fill", color: .systemGreen, get: { settings.deletedExcludePrivate }, set: { settings.deletedExcludePrivate = $0 })),
                    TeleFlowRow(title: "Каналы", kind: .toggle(icon: "megaphone.fill", color: .systemBlue, get: { settings.deletedExcludeChannels }, set: { settings.deletedExcludeChannels = $0 })),
                    TeleFlowRow(title: "Боты", kind: .toggle(icon: "wrench.and.screwdriver.fill", color: .systemOrange, get: { settings.deletedExcludeBots }, set: { settings.deletedExcludeBots = $0 }))
                ]),
                TeleFlowSection(footer: "Сами сообщения останутся в чатах, но пропадёт пометка об удалении.", rows: [
                    TeleFlowRow(title: "Очистить пометки (\(TeleFlowDeletedStore.shared.count))", kind: .button(isDestructive: true, action: { controller in
                        TeleFlowDeletedStore.shared.removeAll()
                        (controller as? TeleFlowListController)?.reload()
                    }))
                ])
            ]
        })
    }

    static func makeGhostController() -> UIViewController {
        let settings = TeleFlowSettings.shared
        return TeleFlowListController(title: "Ghost", sections: {
            return [
                TeleFlowSection(header: "Ghost", footer: "«Скрыть в сети» — для всех ты будешь не в сети, даже когда пользуешься приложением. «Скрыть печатает» — собеседник не увидит, что ты набираешь сообщение.", rows: [
                    TeleFlowRow(title: "Скрыть «в сети»", kind: .toggle(icon: "eye.slash.fill", color: .systemIndigo, get: { settings.ghostHideOnline }, set: { settings.ghostHideOnline = $0 })),
                    TeleFlowRow(title: "Скрыть «печатает»", kind: .toggle(icon: "keyboard.fill", color: .systemPurple, get: { settings.ghostHideTyping }, set: { settings.ghostHideTyping = $0 })),
                    TeleFlowRow(title: "Не отправлять прочтение", kind: .toggle(icon: "checkmark.message.fill", color: .systemTeal, get: { settings.ghostHideReadReceipts }, set: { settings.ghostHideReadReceipts = $0 }))
                ])
            ]
        })
    }

    static func makeOtherController() -> UIViewController {
        let settings = TeleFlowSettings.shared
        return TeleFlowListController(title: "Другое", sections: {
            return [
                TeleFlowSection(header: "Отображение информации", footer: "ID аккаунта — твой числовой идентификатор в Telegram.", rows: [
                    TeleFlowRow(title: "ID аккаунта", kind: .link(icon: "number", color: .systemBlue, value: {
                        let id = TeleFlowSettings.shared.accountId
                        return id != 0 ? "\(id)" : "—"
                    }, action: { _ in
                        UIPasteboard.general.string = "\(TeleFlowSettings.shared.accountId)"
                    }))
                ]),
                TeleFlowSection(header: "Реклама", footer: "Спонсорские сообщения в каналах и в поиске не показываются.", rows: [
                    TeleFlowRow(title: "Убрать рекламу в каналах", kind: .toggle(icon: "megaphone.fill", color: .systemRed, get: { settings.hideSponsoredMessages }, set: { settings.hideSponsoredMessages = $0 }))
                ])
            ]
        })
    }

    static func makeLocalStarsController() -> UIViewController {
        let settings = TeleFlowSettings.shared
        return TeleFlowListController(title: "Локальные звёзды", sections: {
            return [
                TeleFlowSection(header: "Звёзды Telegram", footer: "Локально подменяет отображаемый баланс звёзд. На реальный баланс и покупки не влияет.", rows: [
                    TeleFlowRow(title: "Изменить баланс звёзд", kind: .toggle(icon: "star.fill", color: .systemYellow, get: { settings.localStarsEnabled }, set: { settings.localStarsEnabled = $0 })),
                    TeleFlowRow(title: "Значение баланса", kind: .link(icon: nil, color: nil, value: {
                        return "\(settings.localStarsValue)"
                    }, action: { controller in
                        let alert = UIAlertController(title: "Баланс звёзд", message: "Введи число, которое будет показано", preferredStyle: .alert)
                        alert.addTextField { tf in
                            tf.keyboardType = .numberPad
                            tf.text = "\(settings.localStarsValue)"
                        }
                        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
                        alert.addAction(UIAlertAction(title: "Готово", style: .default, handler: { [weak alert, weak controller] _ in
                            if let text = alert?.textFields?.first?.text, let value = Int64(text) {
                                settings.localStarsValue = value
                            }
                            (controller as? TeleFlowListController)?.reload()
                        }))
                        controller.present(alert, animated: true)
                    }))
                ])
            ]
        })
    }

    /// Presents the menu over whatever is currently on screen.
    public static func present(from view: UIView?) {
        guard let rootController = view?.window?.rootViewController else {
            return
        }
        var topController = rootController
        while let presented = topController.presentedViewController {
            topController = presented
        }
        if topController is UINavigationController, topController.children.first is TeleFlowListController {
            return
        }
        let controller = TeleFlowMenu.makeController()
        controller.modalPresentationStyle = .pageSheet
        topController.present(controller, animated: true)
    }
}

// MARK: - Triple tap detection

public final class TeleFlowTapCounter {
    public static let shared = TeleFlowTapCounter()

    private var lastTapTime: CFAbsoluteTime = 0.0
    private var count = 0

    /// Registers one tap. Returns true when this tap completes a triple tap.
    public func registerTap() -> Bool {
        let now = CFAbsoluteTimeGetCurrent()
        if now - self.lastTapTime > 0.45 {
            self.count = 0
        }
        self.lastTapTime = now
        self.count += 1
        if self.count >= 3 {
            self.count = 0
            return true
        }
        return false
    }
}

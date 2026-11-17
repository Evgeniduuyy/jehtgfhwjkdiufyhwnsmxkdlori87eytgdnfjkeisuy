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
                    })),
                    TeleFlowRow(title: "Локальные gram", kind: .link(icon: "flame.fill", color: .systemOrange, value: {
                        return TeleFlowSettings.shared.localGramEnabled ? "\(TeleFlowSettings.shared.localGramValue)" : nil
                    }, action: { controller in
                        controller.navigationController?.pushViewController(TeleFlowMenu.makeLocalGramController(), animated: true)
                    })),
                    TeleFlowRow(title: "Маркет подарков (визуал)", kind: .link(icon: "bag.fill", color: .systemPink, value: {
                        return "витрина: \(TeleFlowGiftStore.shared.count)"
                    }, action: { controller in
                        controller.navigationController?.pushViewController(TeleFlowMenu.makeMarketController(), animated: true)
                    })),
                    TeleFlowRow(title: "Чат и интерфейс", kind: .link(icon: "message.fill", color: .systemGreen, value: { nil }, action: { controller in
                        controller.navigationController?.pushViewController(TeleFlowMenu.makeChatInterfaceController(), animated: true)
                    })),
                    TeleFlowRow(title: "Настройки мода", kind: .link(icon: "gearshape.fill", color: .systemGray, value: { nil }, action: { controller in
                        controller.navigationController?.pushViewController(TeleFlowMenu.makeModSettingsController(), animated: true)
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
                TeleFlowSection(header: "Профиль", footer: "ID под именем — у всех пользователей. Бейдж «Пользователь KinopoiskGram» — в чужих профилях. Всё это видно только на этом устройстве.", rows: [
                    TeleFlowRow(title: "Показывать ID в профилях", kind: .toggle(icon: "number", color: .systemBlue, get: { settings.showPeerIdInProfile }, set: { settings.showPeerIdInProfile = $0 })),
                    TeleFlowRow(title: "Бейдж «Пользователь KinopoiskGram»", kind: .toggle(icon: "app.badge.fill", color: .systemBlue, get: { settings.showKinopoiskBadge }, set: { settings.showKinopoiskBadge = $0 })),
                    TeleFlowRow(title: "Текст бейджа", kind: .link(icon: nil, color: nil, value: { settings.kinopoiskBadgeText }, action: { controller in
                        let alert = UIAlertController(title: "Текст бейджа", message: "Что показывать в чужих профилях", preferredStyle: .alert)
                        alert.addTextField { tf in
                            tf.text = settings.kinopoiskBadgeText
                        }
                        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
                        alert.addAction(UIAlertAction(title: "Готово", style: .default, handler: { [weak alert, weak controller] _ in
                            if let text = alert?.textFields?.first?.text, !text.isEmpty {
                                settings.kinopoiskBadgeText = String(text.prefix(40))
                            }
                            (controller as? TeleFlowListController)?.reload()
                        }))
                        controller.present(alert, animated: true)
                    }))
                ]),
                TeleFlowSection(header: "Реклама", footer: "Спонсорские сообщения в каналах и в поиске не показываются.", rows: [
                    TeleFlowRow(title: "Убрать рекламу в каналах", kind: .toggle(icon: "megaphone.fill", color: .systemRed, get: { settings.hideSponsoredMessages }, set: { settings.hideSponsoredMessages = $0 }))
                ])
            ]
        })
    }

    static func makeChatInterfaceController() -> UIViewController {
        let settings = TeleFlowSettings.shared
        return TeleFlowListController(title: "Чат и интерфейс", sections: {
            return [
                TeleFlowSection(header: "Сообщения", footer: "Всё применяется локально, на этом устройстве: настоящие сообщения не меняются.", rows: [
                    TeleFlowRow(title: "Zalgo-фильтр", kind: .toggle(icon: "textformat.123", color: .systemPurple, get: { settings.zalgoFilter }, set: { settings.zalgoFilter = $0 })),
                    TeleFlowRow(title: "Полное время у системных сообщений", kind: .toggle(icon: "clock.fill", color: .systemBlue, get: { settings.fullTimeServiceMessages }, set: { settings.fullTimeServiceMessages = $0 }))
                ]),
                TeleFlowSection(header: "Профиль", footer: "Вкладка «Подарки» в профилях не показывается.", rows: [
                    TeleFlowRow(title: "Скрыть вкладку «Подарки» в профиле", kind: .toggle(icon: "gift.fill", color: .systemPink, get: { settings.hideGiftsTab }, set: { settings.hideGiftsTab = $0 }))
                ]),
                TeleFlowSection(header: "Стикеры", footer: "Локальный размер показа стикеров в чатах: 50%–150%. На отправку не влияет.", rows: [
                    TeleFlowRow(title: "Размер стикеров", kind: .link(icon: "rectangle.on.rectangle.angled", color: .systemTeal, value: {
                        return "\(settings.stickerSizePercent)%"
                    }, action: { controller in
                        let alert = UIAlertController(title: "Размер стикеров", message: "Проценты от обычного размера (50–150)", preferredStyle: .alert)
                        alert.addTextField { tf in
                            tf.keyboardType = .numberPad
                            tf.text = "\(settings.stickerSizePercent)"
                        }
                        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
                        alert.addAction(UIAlertAction(title: "Готово", style: .default, handler: { [weak alert, weak controller] _ in
                            if let text = alert?.textFields?.first?.text, let value = Int(text) {
                                settings.stickerSizePercent = value
                            }
                            (controller as? TeleFlowListController)?.reload()
                        }))
                        controller.present(alert, animated: true)
                    }))
                ])
            ]
        })
    }

    static func makeModSettingsController() -> UIViewController {
        let settings = TeleFlowSettings.shared
        return TeleFlowListController(title: "Настройки мода", sections: {
            return [
                TeleFlowSection(header: "Экспорт и импорт", footer: "Все переключатели KinopoiskGram одним файлом JSON — удобно при переустановке. Экспорт кладёт текст в буфер обмена и открывает меню «Поделиться».", rows: [
                    TeleFlowRow(title: "Экспорт настроек (JSON)", kind: .button(isDestructive: false, action: { controller in
                        guard let data = try? JSONSerialization.data(withJSONObject: settings.makeExport(), options: [.prettyPrinted, .sortedKeys]), let json = String(data: data, encoding: .utf8) else {
                            return
                        }
                        UIPasteboard.general.string = json
                        let activity = UIActivityViewController(activityItems: [json], applicationActivities: nil)
                        if let popover = activity.popoverPresentationController {
                            popover.sourceView = controller.view
                            popover.sourceRect = CGRect(x: controller.view.bounds.midX, y: controller.view.bounds.midY, width: 0.0, height: 0.0)
                        }
                        controller.present(activity, animated: true)
                    })),
                    TeleFlowRow(title: "Импорт настроек (JSON)", kind: .button(isDestructive: false, action: { controller in
                        let alert = UIAlertController(title: "Импорт настроек", message: "Вставь JSON с настройками", preferredStyle: .alert)
                        alert.addTextField { tf in
                            if let json = UIPasteboard.general.string {
                                tf.text = json
                            }
                        }
                        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
                        alert.addAction(UIAlertAction(title: "Импортировать", style: .default, handler: { [weak alert, weak controller] _ in
                            guard let text = alert?.textFields?.first?.text, let data = text.data(using: .utf8), let values = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                                return
                            }
                            settings.applyImport(values)
                            (controller as? TeleFlowListController)?.reload()
                        }))
                        controller.present(alert, animated: true)
                    })),
                    TeleFlowRow(title: "Сбросить все настройки мода", kind: .button(isDestructive: true, action: { controller in
                        let alert = UIAlertController(title: "Сбросить настройки?", message: "Все переключатели вернутся к значениям по умолчанию. Витрина и записи не трогаются.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Сбросить", style: .destructive, handler: { [weak controller] _ in
                            for (key, _) in settings.makeExport() {
                                UserDefaults.standard.removeObject(forKey: key)
                            }
                            (controller as? TeleFlowListController)?.reload()
                        }))
                        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
                        controller.present(alert, animated: true)
                    }))
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

    // MARK: Local gram (visual-only)

    static func makeLocalGramController() -> UIViewController {
        let settings = TeleFlowSettings.shared
        let store = TeleFlowGiftStore.shared
        return TeleFlowListController(title: "Локальные gram", sections: {
            return [
                TeleFlowSection(header: "Gram", footer: "Визуальный баланс gram: показывается в твоём профиле и в маркет-витрине мода. Настоящий баланс и покупки Telegram не затрагиваются, всё остаётся только на этом устройстве.", rows: [
                    TeleFlowRow(title: "Показывать баланс в профиле", kind: .toggle(icon: "flame.fill", color: .systemOrange, get: { settings.localGramEnabled }, set: { settings.localGramEnabled = $0 })),
                    TeleFlowRow(title: "Текущий баланс", kind: .link(icon: nil, color: nil, value: {
                        return "🔥 \(settings.localGramValue)"
                    }, action: { controller in
                        let alert = UIAlertController(title: "Установить баланс gram", message: "Разница со старым значением будет записана в историю.", preferredStyle: .alert)
                        alert.addTextField { tf in
                            tf.keyboardType = .numberPad
                            tf.text = "\(settings.localGramValue)"
                        }
                        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
                        alert.addAction(UIAlertAction(title: "Готово", style: .default, handler: { [weak alert, weak controller] _ in
                            if let text = alert?.textFields?.first?.text, let value = Int64(text) {
                                store.setLocalGramBalance(value)
                            }
                            (controller as? TeleFlowListController)?.reload()
                        }))
                        controller.present(alert, animated: true)
                    })),
                    TeleFlowRow(title: "Пополнить баланс (визуально)", kind: .link(icon: "plus.circle.fill", color: .systemGreen, value: { nil }, action: { controller in
                        let alert = UIAlertController(title: "Пополнить gram", message: "Введи сумму визуального пополнения", preferredStyle: .alert)
                        alert.addTextField { tf in
                            tf.keyboardType = .numberPad
                            tf.placeholder = "Сумма gram"
                        }
                        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
                        alert.addAction(UIAlertAction(title: "Пополнить", style: .default, handler: { [weak alert, weak controller] _ in
                            if let text = alert?.textFields?.first?.text, let value = Int64(text) {
                                _ = store.topUpLocalGram(value)
                            }
                            (controller as? TeleFlowListController)?.reload()
                        }))
                        controller.present(alert, animated: true)
                    })),
                    TeleFlowRow(title: "История баланса", kind: .link(icon: "clock.arrow.circlepath", color: .systemBlue, value: {
                        let count = store.transactionCount
                        return count > 0 ? "\(count)" : nil
                    }, action: { controller in
                        controller.navigationController?.pushViewController(TeleFlowMenu.makeGramHistoryController(), animated: true)
                    })),
                    TeleFlowRow(title: "Подарить gram (визуально)", kind: .link(icon: "paperplane.fill", color: .systemOrange, value: {
                        let count = store.allTransfers.filter { $0.isGram }.count
                        return count > 0 ? "\(count)" : nil
                    }, action: { controller in
                        controller.navigationController?.pushViewController(TeleFlowMenu.makeGiftGramController(), animated: true)
                    }))
                ])
            ]
        })
    }

    static func makeGramHistoryController() -> UIViewController {
        return TeleFlowListController(title: "История gram", sections: {
            var rows: [TeleFlowRow] = []
            for transaction in TeleFlowGiftStore.shared.allTransactions {
                let icon: String
                switch transaction.kind {
                case .topUp:
                    icon = "➕"
                case .adjustment:
                    icon = "✏️"
                case .purchase:
                    icon = "🛍"
                case .gift:
                    icon = "🎁"
                case .transfer:
                    icon = "🔥"
                }
                let sign = transaction.amount > 0 ? "+" : ""
                rows.append(TeleFlowRow(title: "\(icon) \(transaction.title)", kind: .link(icon: nil, color: nil, value: {
                    return "\(sign)\(transaction.amount) 🔥"
                }, action: { controller in
                    var details = "\(TeleFlowMenu.gramDateString(transaction.date))\n\nОперация: \(sign)\(transaction.amount) gram\nБаланс после: \(transaction.balanceAfter) gram"
                    if !transaction.recipientName.isEmpty {
                        details += "\nПолучатель: \(transaction.recipientName)"
                    }
                    let alert = UIAlertController(title: transaction.title, message: details, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ок", style: .cancel))
                    controller.present(alert, animated: true)
                })))
            }
            if rows.isEmpty {
                rows.append(TeleFlowRow(title: "Операций пока не было", kind: .choice(isSelected: { false }, action: {})))
            }
            return [
                TeleFlowSection(header: "Пополнения и списания", footer: "Плюс — визуальное пополнение, минус — покупка, подарок или перевод. История хранится только на этом устройстве.", rows: rows),
                TeleFlowSection(rows: [
                    TeleFlowRow(title: "Очистить историю баланса", kind: .button(isDestructive: true, action: { controller in
                        TeleFlowGiftStore.shared.removeAllTransactions()
                        (controller as? TeleFlowListController)?.reload()
                    }))
                ])
            ]
        })
    }

    private static func parseRecipient(_ raw: String) -> (name: String, id: Int64) {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let id = Int64(value), id != 0 {
            return ("ID \(id)", id)
        }
        return (value, 0)
    }

    private static func gramDateString(_ timestamp: TimeInterval) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMM yyyy, HH:mm"
        return formatter.string(from: Date(timeIntervalSince1970: timestamp))
    }

    static func makeGiftGramController(recipientName: String = "", recipientId: Int64 = 0) -> UIViewController {
        let settings = TeleFlowSettings.shared
        return TeleFlowListController(title: "Подарить gram (визуал)", sections: {
            var rows: [TeleFlowRow] = [
                TeleFlowRow(title: "Отправить gram человеку (визуально)", kind: .button(isDestructive: false, action: { controller in
                    let alert = UIAlertController(title: "Отправить gram (визуально)", message: "Сумма спишется с локального баланса и попадёт в историю. Настоящие переводы не отправляются.", preferredStyle: .alert)
                    alert.addTextField { tf in
                        tf.placeholder = "@юзернейм или ID"
                        tf.text = recipientName
                    }
                    alert.addTextField { tf in
                        tf.placeholder = "Сумма gram"
                        tf.keyboardType = .numberPad
                    }
                    alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
                    alert.addAction(UIAlertAction(title: "Отправить", style: .default, handler: { [weak alert, weak controller] _ in
                        let recipient = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespaces) ?? ""
                        let amountText = alert?.textFields?.last?.text ?? ""
                        guard !recipient.isEmpty, let amount = Int64(amountText), amount > 0 else {
                            return
                        }
                        let parsed = TeleFlowMenu.parseRecipient(recipient)
                        let id = recipient == recipientName ? recipientId : parsed.id
                        if TeleFlowGiftStore.shared.recordGramTransfer(amount: amount, recipientName: parsed.name, recipientId: id) {
                            controller?.navigationController?.pushViewController(TeleFlowMenu.makeTransfersController(), animated: true)
                        } else if settings.localGramValue < amount {
                            let insufficient = UIAlertController(title: "Не хватает gram", message: "Баланс: \(settings.localGramValue), нужно: \(amount).", preferredStyle: .alert)
                            insufficient.addAction(UIAlertAction(title: "Ок", style: .cancel))
                            controller?.present(insufficient, animated: true)
                        }
                    }))
                    controller.present(alert, animated: true)
                }))
            ]
            for transfer in TeleFlowGiftStore.shared.allTransfers.filter({ $0.isGram }) {
                rows.append(TeleFlowRow(title: "\(transfer.emoji) → \(transfer.recipientName)", kind: .link(icon: nil, color: nil, value: { "−\(transfer.amount) gram" }, action: { _ in })))
            }
            if TeleFlowGiftStore.shared.allTransfers.filter({ $0.isGram }).isEmpty {
                rows.append(TeleFlowRow(title: "Пока нет визуальных переводов", kind: .choice(isSelected: { false }, action: {})))
            }
            return [
                TeleFlowSection(header: "Визуальные переводы", footer: "Показываются только в этом меню. Каждый перевод списывает локальные gram и остаётся в истории баланса.", rows: rows)
            ]
        })
    }

    static func makeTransfersController() -> UIViewController {
        return TeleFlowListController(title: "Подарено (визуал)", sections: {
            var rows: [TeleFlowRow] = []
            for transfer in TeleFlowGiftStore.shared.allTransfers {
                let title: String
                let value: String?
                if transfer.isGram {
                    title = "🔥 \(transfer.amount) gram → \(transfer.recipientName)"
                    value = "−\(transfer.amount) 🔥"
                } else {
                    title = "\(transfer.emoji) \(transfer.title) → \(transfer.recipientName)"
                    value = transfer.amount > 0 ? "🔥 \(transfer.amount)" : nil
                }
                rows.append(TeleFlowRow(title: title, kind: .link(icon: nil, color: nil, value: { value }, action: { controller in
                    var details = "Визуальная запись. Настоящий подарок или перевод не отправлялся.\n\n\(TeleFlowMenu.gramDateString(transfer.date))\nПолучатель: \(transfer.recipientName)"
                    if transfer.recipientId != 0 {
                        details += "\nID: \(transfer.recipientId)"
                    }
                    if transfer.isGram {
                        details += "\nСписано: \(transfer.amount) gram"
                    } else if transfer.amount > 0 {
                        details += "\nВизуальная цена: \(transfer.amount) gram"
                    }
                    let alert = UIAlertController(title: title, message: details, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Удалить запись", style: .destructive, handler: { _ in
                        TeleFlowGiftStore.shared.removeTransfer(uid: transfer.uid)
                        (controller as? TeleFlowListController)?.reload()
                    }))
                    alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
                    controller.present(alert, animated: true)
                })))
            }
            if rows.isEmpty {
                rows.append(TeleFlowRow(title: "Пока ничего не подарено (визуально)", kind: .choice(isSelected: { false }, action: {})))
            }
            return [
                TeleFlowSection(header: "Журнал", footer: "Локальные записи о визуальных подарках и переводах gram. Никому ничего не отправляется.", rows: rows),
                TeleFlowSection(footer: nil, rows: [
                    TeleFlowRow(title: "Очистить журнал", kind: .button(isDestructive: true, action: { controller in
                        TeleFlowGiftStore.shared.removeAllTransfers()
                        (controller as? TeleFlowListController)?.reload()
                    }))
                ])
            ]
        })
    }

    // MARK: Market (visual showcase)

    static func makeMarketController() -> UIViewController {
        return TeleFlowListController(title: "Маркет (визуал)", sections: {
            return [
                TeleFlowSection(header: "Витрина", footer: "Твои визуальные подарки и крафт. Они живут только в этом меню — их не видно никому и нигде в настоящем Telegram.", rows: [
                    TeleFlowRow(title: "Открыть витрину (\(TeleFlowGiftStore.shared.count))", kind: .link(icon: "sparkles", color: .systemYellow, value: { nil }, action: { controller in
                        controller.navigationController?.pushViewController(TeleFlowMenu.makeShowcaseController(), animated: true)
                    })),
                    TeleFlowRow(title: "Подарено (визуально) (\(TeleFlowGiftStore.shared.transferCount))", kind: .link(icon: "paperplane.fill", color: .systemOrange, value: { nil }, action: { controller in
                        controller.navigationController?.pushViewController(TeleFlowMenu.makeTransfersController(), animated: true)
                    })),
                    TeleFlowRow(title: "История баланса (\(TeleFlowGiftStore.shared.transactionCount))", kind: .link(icon: "clock.arrow.circlepath", color: .systemBlue, value: { nil }, action: { controller in
                        controller.navigationController?.pushViewController(TeleFlowMenu.makeGramHistoryController(), animated: true)
                    })),
                    TeleFlowRow(title: "Очистить витрину", kind: .button(isDestructive: true, action: { controller in
                        TeleFlowGiftStore.shared.removeAll()
                        (controller as? TeleFlowListController)?.reload()
                    }))
                ]),
                TeleFlowSection(header: "Архивные NFT", footer: "Добавь снятый с продажи или недоступный NFT как локальную карточку. Она появится в твоём визуальном профиле; её можно улучшить и визуально отправить себе. Это не настоящий NFT.", rows: [
                    TeleFlowRow(title: "Добавить архивный NFT в профиль", kind: .link(icon: "plus.square.fill", color: .systemPurple, value: {
                        let count = TeleFlowGiftStore.shared.all.filter { $0.archived }.count
                        return count > 0 ? "\(count)" : nil
                    }, action: { controller in
                        TeleFlowMenu.addArchivedGift(controller: controller)
                    }))
                ]),
                TeleFlowSection(header: "Каталог", footer: "Покупка тратит локальные gram. Баланс меняется в разделе «Локальные gram».", rows: TeleFlowGiftStore.catalog.map { gift in
                    return TeleFlowRow(title: "\(gift.emoji) \(gift.name)", kind: .link(icon: nil, color: nil, value: {
                        return "🔥 \(gift.priceGram)"
                    }, action: { controller in
                        TeleFlowMenu.buyGift(gift, controller: controller)
                    }))
                })
            ]
        })
    }

    private static func addArchivedGift(controller: UIViewController) {
        let alert = UIAlertController(title: "Архивный NFT", message: "Локальная карточка подарка, которого нет в продаже. Название обязательно, остальное — по желанию.", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Название, например ChillFlame"
        }
        alert.addTextField { tf in
            tf.placeholder = "Эмодзи (по умолчанию 🎁)"
        }
        alert.addTextField { tf in
            tf.placeholder = "Номер, например 281762"
            tf.keyboardType = .numberPad
        }
        alert.addTextField { tf in
            tf.placeholder = "https://t.me/nft/… (необязательно)"
            if let clipboard = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines), clipboard.lowercased().contains("t.me/nft/") {
                tf.text = clipboard
            }
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Добавить в профиль", style: .default, handler: { [weak alert, weak controller] _ in
            guard let fields = alert?.textFields, fields.count == 4 else {
                return
            }
            let name = fields[0].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let emoji = fields[1].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let number = fields[2].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            var link = fields[3].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !name.isEmpty else {
                return
            }
            if !link.isEmpty {
                if link.lowercased().hasPrefix("t.me/nft/") {
                    link = "https://" + link
                }
                guard link.lowercased().hasPrefix("https://t.me/nft/") else {
                    let error = UIAlertController(title: "Неверная ссылка", message: "Для архивной карточки разрешена только официальная ссылка вида https://t.me/nft/…", preferredStyle: .alert)
                    error.addAction(UIAlertAction(title: "Ок", style: .cancel))
                    controller?.present(error, animated: true)
                    return
                }
            }
            let gift = TeleFlowGiftStore.shared.addArchived(name: name, emoji: String(emoji.prefix(4)), nftLink: link, giftNumber: number)
            if let controller = controller {
                TeleFlowMenu.playGiftSentAnimation(emoji: gift.emoji, recipientName: "Мой профиль", controller: controller, completion: {
                    (controller as? TeleFlowListController)?.reload()
                })
            }
        }))
        controller.present(alert, animated: true)
    }

    private static func buyGift(_ gift: TeleFlowShowcaseGift, controller: UIViewController) {
        let settings = TeleFlowSettings.shared
        if settings.localGramValue < gift.priceGram {
            let alert = UIAlertController(title: "Не хватает gram", message: "Баланс: \(settings.localGramValue), нужно: \(gift.priceGram). Баланс визуальный — можешь поднять его в «Локальных gram».", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Открыть «Локальные gram»", style: .default, handler: { _ in
                controller.navigationController?.pushViewController(TeleFlowMenu.makeLocalGramController(), animated: true)
            }))
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            controller.present(alert, animated: true)
            return
        }
        let confirm = UIAlertController(title: "\(gift.emoji) \(gift.name)", message: "Купить за 🔥 \(gift.priceGram) gram? Подарок появится в визуальной витрине мода.", preferredStyle: .alert)
        confirm.addAction(UIAlertAction(title: "Купить", style: .default, handler: { _ in
            if TeleFlowGiftStore.shared.purchase(gift) {
                controller.navigationController?.pushViewController(TeleFlowMenu.makeShowcaseController(), animated: true)
            }
        }))
        confirm.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        controller.present(confirm, animated: true)
    }

    // MARK: Chat market (visual only, recipient-aware)

    static func makeChatMarketController(recipientName: String, recipientId: Int64) -> UIViewController {
        let recipient = recipientName.isEmpty ? (recipientId != 0 ? "ID \(recipientId)" : "Собеседник") : recipientName
        let store = TeleFlowGiftStore.shared
        return TeleFlowListController(title: "Маркет · \(recipient)", sections: {
            let settings = TeleFlowSettings.shared
            let chatTransfers = store.allTransfers.filter { transfer in
                if recipientId != 0 {
                    return transfer.recipientId == recipientId
                }
                return transfer.recipientName.caseInsensitiveCompare(recipient) == .orderedSame
            }

            var sentRows: [TeleFlowRow] = chatTransfers.map { transfer in
                let title = transfer.isGram ? "🔥 \(transfer.amount) gram" : "\(transfer.emoji) \(transfer.title)"
                return TeleFlowRow(title: title, kind: .link(icon: nil, color: nil, value: { "визуально" }, action: { controller in
                    let alert = UIAlertController(title: title, message: "Визуальный подарок для \(transfer.recipientName).\n\(TeleFlowMenu.gramDateString(transfer.date))\n\nНастоящее сообщение или подарок в Telegram не отправлялись.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ок", style: .cancel))
                    controller.present(alert, animated: true)
                }))
            }
            if sentRows.isEmpty {
                sentRows.append(TeleFlowRow(title: "В этом чате пока нет визуальных подарков", kind: .choice(isSelected: { false }, action: {})))
            }

            var showcaseRows: [TeleFlowRow] = store.all.map { gift in
                return TeleFlowRow(title: "\(gift.emoji) \(gift.name)", kind: .link(icon: nil, color: nil, value: { gift.inProfile ? "📌" : nil }, action: { controller in
                    TeleFlowMenu.confirmShowcaseChatGift(gift, recipientName: recipient, recipientId: recipientId, controller: controller)
                }))
            }
            if showcaseRows.isEmpty {
                showcaseRows.append(TeleFlowRow(title: "Витрина пуста", kind: .choice(isSelected: { false }, action: {})))
            }

            let recipientDescription = recipientId != 0 ? "\(recipient) · ID \(recipientId)" : recipient
            return [
                TeleFlowSection(header: "Получатель: \(recipientDescription)", footer: "Всё на этом экране — локальный визуал. Собеседник ничего не получает, настоящие сообщения и балансы Telegram не меняются.", rows: [
                    TeleFlowRow(title: "Баланс gram", kind: .link(icon: "flame.fill", color: .systemOrange, value: {
                        return "🔥 \(settings.localGramValue)"
                    }, action: { controller in
                        controller.navigationController?.pushViewController(TeleFlowMenu.makeLocalGramController(), animated: true)
                    })),
                    TeleFlowRow(title: "История пополнений и списаний", kind: .link(icon: "clock.arrow.circlepath", color: .systemBlue, value: {
                        return store.transactionCount > 0 ? "\(store.transactionCount)" : nil
                    }, action: { controller in
                        controller.navigationController?.pushViewController(TeleFlowMenu.makeGramHistoryController(), animated: true)
                    })),
                    TeleFlowRow(title: "Подарить gram этому человеку", kind: .link(icon: "paperplane.fill", color: .systemOrange, value: { nil }, action: { controller in
                        controller.navigationController?.pushViewController(TeleFlowMenu.makeGiftGramController(recipientName: recipient, recipientId: recipientId), animated: true)
                    }))
                ]),
                TeleFlowSection(header: "Подарить из каталога", footer: "Цена спишется с визуального баланса. Операция появится в истории gram и в локальном журнале этого чата.", rows: TeleFlowGiftStore.catalog.map { gift in
                    return TeleFlowRow(title: "\(gift.emoji) \(gift.name)", kind: .link(icon: nil, color: nil, value: {
                        return "🔥 \(gift.priceGram)"
                    }, action: { controller in
                        TeleFlowMenu.confirmCatalogChatGift(gift, recipientName: recipient, recipientId: recipientId, controller: controller)
                    }))
                }),
                TeleFlowSection(header: "Подарить с моей витрины", footer: "Подарок уйдёт с локальной витрины. Повторное списание gram не производится — он уже был куплен.", rows: showcaseRows),
                TeleFlowSection(header: "Визуально подарено в этом чате", rows: sentRows)
            ]
        })
    }

    private static func confirmCatalogChatGift(_ gift: TeleFlowShowcaseGift, recipientName: String, recipientId: Int64, controller: UIViewController) {
        let settings = TeleFlowSettings.shared
        guard settings.localGramValue >= gift.priceGram else {
            TeleFlowMenu.showInsufficientGram(required: gift.priceGram, controller: controller)
            return
        }
        let alert = UIAlertController(title: "\(gift.emoji) \(gift.name)", message: "Визуально подарить \(recipientName) за 🔥 \(gift.priceGram) gram?\n\nС баланса спишется \(gift.priceGram) gram. Настоящий подарок не отправляется.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Подарить визуально", style: .default, handler: { [weak controller] _ in
            if TeleFlowGiftStore.shared.giftCatalogGift(gift, recipientName: recipientName, recipientId: recipientId), let controller = controller {
                TeleFlowMenu.playGiftSentAnimation(emoji: gift.emoji, recipientName: recipientName, controller: controller, completion: {
                    (controller as? TeleFlowListController)?.reload()
                })
            }
        }))
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        controller.present(alert, animated: true)
    }

    private static func confirmShowcaseChatGift(_ gift: TeleFlowShowcaseGift, recipientName: String, recipientId: Int64, controller: UIViewController) {
        let alert = UIAlertController(title: "\(gift.emoji) \(gift.name)", message: "Визуально подарить \(recipientName)? Подарок уйдёт с твоей локальной витрины, настоящий подарок не отправляется.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Подарить визуально", style: .default, handler: { [weak controller] _ in
            TeleFlowGiftStore.shared.giftAway(uid: gift.uid, recipientName: recipientName, recipientId: recipientId)
            if let controller = controller {
                TeleFlowMenu.playGiftSentAnimation(emoji: gift.emoji, recipientName: recipientName, controller: controller, completion: {
                    (controller as? TeleFlowListController)?.reload()
                })
            }
        }))
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        controller.present(alert, animated: true)
    }

    private static func showInsufficientGram(required: Int64, controller: UIViewController) {
        let balance = TeleFlowSettings.shared.localGramValue
        let alert = UIAlertController(title: "Не хватает gram", message: "Баланс: \(balance), нужно: \(required). Можно визуально пополнить баланс в разделе «Локальные gram».", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Пополнить", style: .default, handler: { _ in
            controller.navigationController?.pushViewController(TeleFlowMenu.makeLocalGramController(), animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        controller.present(alert, animated: true)
    }

    private static func playGiftSentAnimation(emoji: String, recipientName: String, controller: UIViewController, completion: @escaping () -> Void) {
        guard let view = controller.navigationController?.view ?? controller.view else {
            completion()
            return
        }
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor(white: 0.0, alpha: 0.7)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(overlay)

        let giftLabel = UILabel()
        giftLabel.text = emoji
        giftLabel.font = UIFont.systemFont(ofSize: 76.0)
        giftLabel.sizeToFit()
        giftLabel.center = CGPoint(x: overlay.bounds.midX, y: overlay.bounds.midY - 42.0)
        overlay.addSubview(giftLabel)

        let statusLabel = UILabel()
        statusLabel.text = "✓ Визуально подарено\n\(recipientName)"
        statusLabel.textColor = .white
        statusLabel.font = UIFont.systemFont(ofSize: 18.0, weight: .semibold)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.frame = CGRect(x: 24.0, y: overlay.bounds.midY + 22.0, width: overlay.bounds.width - 48.0, height: 70.0)
        overlay.addSubview(statusLabel)

        giftLabel.transform = CGAffineTransform(scaleX: 0.35, y: 0.35)
        statusLabel.alpha = 0.0
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.55, initialSpringVelocity: 0.7, options: [], animations: {
            giftLabel.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            statusLabel.alpha = 1.0
        }, completion: nil)
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            UIView.animate(withDuration: 0.25, animations: {
                overlay.alpha = 0.0
            }, completion: { _ in
                overlay.removeFromSuperview()
                completion()
            })
        }
    }

    // MARK: Showcase (owned visual gifts, upgrade & craft)

    static func makeShowcaseController() -> UIViewController {
        return TeleFlowListController(title: "Витрина", sections: {
            var rows: [TeleFlowRow] = []
            let gifts = TeleFlowGiftStore.shared.all
            for gift in gifts {
                var title = (gift.upgraded ? "✨ " : "") + gift.emoji + " " + gift.name + (gift.giftNumber.isEmpty ? "" : " #\(gift.giftNumber)") + (gift.upgraded && !gift.archived ? " · ур. \(gift.priceGram)" : "") + (gift.crafted ? " · крафт" : "") + (gift.archived ? " · архив" : "")
                if gift.inProfile {
                    title += " · 📌 в профиле"
                }
                rows.append(TeleFlowRow(title: title, kind: .link(icon: nil, color: nil, value: { nil }, action: { controller in
                    TeleFlowMenu.showGiftActions(gift, controller: controller)
                })))
            }
            if gifts.isEmpty {
                rows.append(TeleFlowRow(title: "Пока пусто — купи что-нибудь в каталоге", kind: .choice(isSelected: { false }, action: {})))
            }
            return [
                TeleFlowSection(header: "Мои подарки (визуал)", footer: "«Улучшить» — анимация улучшения и номер модели. «Крафт» — соединяет два подарка в новый. Всё только в этом меню.", rows: rows)
            ]
        })
    }

    private static func showGiftActions(_ gift: TeleFlowShowcaseGift, controller: UIViewController) {
        let status: String
        if gift.archived {
            status = gift.upgraded ? "Архивный NFT · улучшен (визуально)" : "Архивный NFT · локальная карточка"
        } else {
            status = gift.upgraded ? "Улучшен · модель №\(gift.priceGram)" : "Не улучшен"
        }
        let alert = UIAlertController(title: "\(gift.emoji) \(gift.name)", message: status, preferredStyle: .actionSheet)
        if let url = URL(string: gift.nftLink), !gift.nftLink.isEmpty {
            alert.addAction(UIAlertAction(title: "Открыть официальную NFT-ссылку", style: .default, handler: { _ in
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }))
        }
        if !gift.upgraded {
            alert.addAction(UIAlertAction(title: "Улучшить ✨", style: .default, handler: { _ in
                TeleFlowMenu.playUpgradeAnimation(emoji: gift.emoji, controller: controller, completion: {
                    TeleFlowGiftStore.shared.setUpgraded(uid: gift.uid, upgraded: true)
                    (controller as? TeleFlowListController)?.reload()
                })
            }))
        }
        alert.addAction(UIAlertAction(title: "Отправить себе в профиль (визуально)", style: .default, handler: { _ in
            TeleFlowGiftStore.shared.sendToProfile(uid: gift.uid)
            TeleFlowMenu.playGiftSentAnimation(emoji: gift.emoji, recipientName: "Мой профиль", controller: controller, completion: {
                (controller as? TeleFlowListController)?.reload()
            })
        }))
        alert.addAction(UIAlertAction(title: "Подарить (визуально)", style: .default, handler: { _ in
            TeleFlowMenu.giftAwayVisually(gift, controller: controller)
        }))
        alert.addAction(UIAlertAction(title: gift.inProfile ? "Убрать из профиля (визуально)" : "В профиль (визуально)", style: .default, handler: { _ in
            TeleFlowGiftStore.shared.setInProfile(uid: gift.uid, inProfile: !gift.inProfile)
            (controller as? TeleFlowListController)?.reload()
        }))
        alert.addAction(UIAlertAction(title: "Крафт: выбрать пару", style: .default, handler: { _ in
            TeleFlowMenu.pickCraftPartner(gift, controller: controller)
        }))
        alert.addAction(UIAlertAction(title: "Убрать с витрины", style: .destructive, handler: { _ in
            TeleFlowGiftStore.shared.remove(uid: gift.uid)
            (controller as? TeleFlowListController)?.reload()
        }))
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        controller.present(alert, animated: true)
    }

    /// Visually gifts a showcase gift to a person. The gift leaves the local showcase
    /// and a record is written to the local journal. Nothing is actually sent anywhere.
    private static func giftAwayVisually(_ gift: TeleFlowShowcaseGift, controller: UIViewController) {
        let alert = UIAlertController(title: "Подарить \(gift.emoji) \(gift.name)", message: "Кому? Запись останется только у тебя — настоящий подарок не отправляется.", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "@юзернейм или ID"
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Подарить", style: .default, handler: { [weak alert, weak controller] _ in
            let recipient = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespaces) ?? ""
            guard !recipient.isEmpty else {
                return
            }
            let parsed = TeleFlowMenu.parseRecipient(recipient)
            TeleFlowGiftStore.shared.giftAway(uid: gift.uid, recipientName: parsed.name, recipientId: parsed.id)
            controller?.navigationController?.pushViewController(TeleFlowMenu.makeTransfersController(), animated: true)
        }))
        controller.present(alert, animated: true)
    }

    private static func pickCraftPartner(_ gift: TeleFlowShowcaseGift, controller: UIViewController) {
        let others = TeleFlowGiftStore.shared.all.filter { $0.uid != gift.uid }
        guard !others.isEmpty else {
            let alert = UIAlertController(title: "Нужна пара", message: "Для крафта нужно два подарка на витрине.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ок", style: .cancel))
            controller.present(alert, animated: true)
            return
        }
        let alert = UIAlertController(title: "Крафт", message: "С чем соединить \(gift.emoji) \(gift.name)?", preferredStyle: .actionSheet)
        for other in others.prefix(8) {
            alert.addAction(UIAlertAction(title: "\(other.emoji) \(other.name)", style: .default, handler: { _ in
                TeleFlowGiftStore.shared.remove(uid: gift.uid)
                TeleFlowGiftStore.shared.remove(uid: other.uid)
                let price = max(10, (gift.priceGram + other.priceGram) / 2 + 20)
                let crafted = TeleFlowShowcaseGift(uid: "crafted." + String(UUID().uuidString.prefix(6)), name: "\(gift.name) + \(other.name)", emoji: "🎁", priceGram: price, upgraded: false, crafted: true)
                _ = TeleFlowGiftStore.shared.add(crafted)
                (controller as? TeleFlowListController)?.reload()
            }))
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        controller.present(alert, animated: true)
    }

    /// A short sparkle animation played over the market screen when a gift is "upgraded".
    private static func playUpgradeAnimation(emoji: String, controller: UIViewController, completion: @escaping () -> Void) {
        guard let view = controller.navigationController?.view ?? controller.view else {
            completion()
            return
        }
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor(white: 0.0, alpha: 0.55)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(overlay)

        let label = UILabel()
        label.text = emoji
        label.font = UIFont.systemFont(ofSize: 72.0)
        label.sizeToFit()
        label.center = CGPoint(x: overlay.bounds.midX, y: overlay.bounds.midY)
        overlay.addSubview(label)

        let sparkles = ["✨", "⭐️", "🌟", "💫"]
        for sparkle in sparkles {
            let sparkleLabel = UILabel()
            sparkleLabel.text = sparkle
            sparkleLabel.font = UIFont.systemFont(ofSize: 24.0)
            sparkleLabel.sizeToFit()
            let angle = CGFloat.random(in: 0.0...(2.0 * .pi))
            let radius: CGFloat = 90.0
            sparkleLabel.center = CGPoint(x: overlay.bounds.midX, y: overlay.bounds.midY)
            overlay.addSubview(sparkleLabel)
            UIView.animate(withDuration: 0.8, delay: 0.05, options: [.curveEaseOut], animations: {
                sparkleLabel.center = CGPoint(x: overlay.bounds.midX + cos(angle) * radius, y: overlay.bounds.midY + sin(angle) * radius)
                sparkleLabel.alpha = 0.0
            }, completion: { _ in
                sparkleLabel.removeFromSuperview()
            })
        }

        label.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
        UIView.animate(withDuration: 0.45, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.6, options: [], animations: {
            label.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }, completion: nil)

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            UIView.animate(withDuration: 0.25, animations: {
                overlay.alpha = 0.0
            }, completion: { _ in
                overlay.removeFromSuperview()
                completion()
            })
        }
    }

    /// Presents the recipient-aware visual market over the current chat.
    public static func presentChatMarket(from view: UIView?, recipientName: String, recipientId: Int64) {
        guard let rootController = view?.window?.rootViewController else {
            return
        }
        var topController = rootController
        while let presented = topController.presentedViewController {
            topController = presented
        }
        let root = TeleFlowMenu.makeChatMarketController(recipientName: recipientName, recipientId: recipientId)
        let navigationController = UINavigationController(rootViewController: root)
        navigationController.overrideUserInterfaceStyle = .dark
        navigationController.navigationBar.prefersLargeTitles = false
        navigationController.modalPresentationStyle = .pageSheet
        root.navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: UIAction { [weak navigationController] _ in
            navigationController?.dismiss(animated: true)
        })
        topController.present(navigationController, animated: true)
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

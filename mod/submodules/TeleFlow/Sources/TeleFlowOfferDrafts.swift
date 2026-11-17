import Foundation
import UIKit

// MARK: - Local offer drafts
//
// This is deliberately a local drafting tool, not a marketplace transport. It
// never sends offers, accepts deals, transfers NFTs, or credits any balance.

enum TeleFlowOfferCurrency: String, Codable {
    case gram
    case stars
}

enum TeleFlowOfferLanguage: String, Codable, CaseIterable {
    case ru
    case uk
    case en
    case zh
    case ar

    var title: String {
        switch self {
        case .ru:
            return "Русский"
        case .uk:
            return "Українська"
        case .en:
            return "English"
        case .zh:
            return "中文"
        case .ar:
            return "العربية"
        }
    }
}

struct TeleFlowOfferDraft: Codable, Equatable {
    let uid: String
    let recipient: String
    let nftLink: String
    let amount: Int64
    let currency: TeleFlowOfferCurrency
    let language: TeleFlowOfferLanguage
    let date: TimeInterval

    var giftName: String {
        let component = URL(string: self.nftLink)?.lastPathComponent ?? "NFT"
        if let separator = component.lastIndex(of: "-") {
            let name = String(component[..<separator])
            let number = String(component[component.index(after: separator)...])
            if !name.isEmpty && !number.isEmpty {
                return name + " #" + number
            }
        }
        return component
    }

    private var unit: String {
        switch (self.language, self.currency) {
        case (.ru, .stars):
            return "игровых звёзд"
        case (.ru, .gram):
            return "игровых gram"
        case (.uk, .stars):
            return "ігрових зірок"
        case (.uk, .gram):
            return "ігрових gram"
        case (.en, .stars):
            return "game stars"
        case (.en, .gram):
            return "game gram"
        case (.zh, .stars):
            return "游戏星星"
        case (.zh, .gram):
            return "游戏 gram"
        case (.ar, .stars):
            return "نجوم اللعبة"
        case (.ar, .gram):
            return "gram اللعبة"
        }
    }

    var localizedText: String {
        switch self.language {
        case .ru:
            return "Пользователь предлагает \(self.amount) \(self.unit) за подарок \(self.giftName)."
        case .uk:
            return "Користувач пропонує \(self.amount) \(self.unit) за подарунок \(self.giftName)."
        case .en:
            return "A user offers \(self.amount) \(self.unit) for the \(self.giftName) gift."
        case .zh:
            return "用户提出以 \(self.amount) \(self.unit) 换取礼物 \(self.giftName)。"
        case .ar:
            return "يقترح المستخدم \(self.amount) \(self.unit) مقابل الهدية \(self.giftName)."
        }
    }
}

final class TeleFlowOfferStore {
    static let shared = TeleFlowOfferStore()

    private let draftsPrefix = "teleflow.offerDrafts."
    private let emojiPrefix = "teleflow.offerEmoji."

    private init() {
    }

    private var accountScope: String {
        let accountId = TeleFlowSettings.shared.accountId
        return accountId != 0 ? String(accountId) : "default"
    }

    private func loadDrafts() -> [TeleFlowOfferDraft] {
        guard let data = UserDefaults.standard.data(forKey: self.draftsPrefix + self.accountScope),
              let drafts = try? JSONDecoder().decode([TeleFlowOfferDraft].self, from: data) else {
            return []
        }
        return drafts
    }

    private func saveDrafts(_ drafts: [TeleFlowOfferDraft]) {
        guard let data = try? JSONEncoder().encode(drafts) else {
            return
        }
        UserDefaults.standard.set(data, forKey: self.draftsPrefix + self.accountScope)
    }

    var drafts: [TeleFlowOfferDraft] {
        return self.loadDrafts().sorted { $0.date > $1.date }
    }

    func addDraft(recipient: String, nftLink: String, amount: Int64, currency: TeleFlowOfferCurrency, language: TeleFlowOfferLanguage) -> TeleFlowOfferDraft {
        let draft = TeleFlowOfferDraft(
            uid: "offer." + String(UUID().uuidString.prefix(8)),
            recipient: recipient,
            nftLink: nftLink,
            amount: amount,
            currency: currency,
            language: language,
            date: Date().timeIntervalSince1970
        )
        var current = self.loadDrafts()
        current.append(draft)
        self.saveDrafts(current)
        return draft
    }

    func removeDraft(uid: String) {
        self.saveDrafts(self.loadDrafts().filter { $0.uid != uid })
    }

    func removeAllDrafts() {
        self.saveDrafts([])
    }

    private func emojiId(_ name: String) -> String {
        return UserDefaults.standard.string(forKey: self.emojiPrefix + self.accountScope + "." + name) ?? ""
    }

    private func setEmojiId(_ name: String, value: String) {
        UserDefaults.standard.set(value, forKey: self.emojiPrefix + self.accountScope + "." + name)
    }

    var starEmojiId: String {
        get { return self.emojiId("stars") }
        set { self.setEmojiId("stars", value: newValue) }
    }

    var gramEmojiId: String {
        get { return self.emojiId("gram") }
        set { self.setEmojiId("gram", value: newValue) }
    }

    var giftEmojiId: String {
        get { return self.emojiId("gift") }
        set { self.setEmojiId("gift", value: newValue) }
    }
}

// MARK: - Draft list and wizard

extension TeleFlowMenu {
    static func makeOfferDraftsController() -> UIViewController {
        let store = TeleFlowOfferStore.shared
        return TeleFlowListController(title: "Черновики предложений", sections: {
            var rows: [TeleFlowRow] = [
                TeleFlowRow(title: "Сделать предложение (черновик)", kind: .link(icon: "plus.circle.fill", color: .systemGreen, value: { nil }, action: { controller in
                    TeleFlowMenu.startOfferDraft(controller: controller)
                })),
                TeleFlowRow(title: "Изменить эмодзи", kind: .link(icon: "face.smiling.fill", color: .systemYellow, value: { nil }, action: { controller in
                    controller.navigationController?.pushViewController(TeleFlowMenu.makeOfferEmojiController(), animated: true)
                }))
            ]
            for draft in store.drafts {
                let unit = draft.currency == .stars ? "⭐" : "gram"
                rows.append(TeleFlowRow(title: "🎁 \(draft.giftName) → \(draft.recipient)", kind: .link(icon: nil, color: nil, value: {
                    return "\(draft.amount) \(unit)"
                }, action: { controller in
                    controller.navigationController?.pushViewController(TeleFlowOfferPreviewController(draft: draft), animated: true)
                })))
            }
            if store.drafts.isEmpty {
                rows.append(TeleFlowRow(title: "Локальных черновиков пока нет", kind: .choice(isSelected: { false }, action: {})))
            }
            return [
                TeleFlowSection(header: "Только локальные черновики", footer: "Предложения никому не отправляются. Здесь нет принятия сделки, перевода валюты или передачи NFT. Внутренние игровые единицы не являются Telegram Stars.", rows: rows),
                TeleFlowSection(rows: [
                    TeleFlowRow(title: "Удалить все черновики", kind: .button(isDestructive: true, action: { controller in
                        store.removeAllDrafts()
                        (controller as? TeleFlowListController)?.reload()
                    }))
                ])
            ]
        })
    }

    private static func makeOfferEmojiController() -> UIViewController {
        let store = TeleFlowOfferStore.shared
        return TeleFlowListController(title: "Эмодзи черновиков", sections: {
            return [
                TeleFlowSection(header: "Premium emoji ID", footer: "Можно ввести просто ID или формат «* - ID». Значения сохраняются отдельно для текущего аккаунта и показываются в локальной карточке.", rows: [
                    TeleFlowMenu.offerEmojiRow(title: "Звезда ⭐", get: { store.starEmojiId }, set: { store.starEmojiId = $0 }),
                    TeleFlowMenu.offerEmojiRow(title: "Грамм", get: { store.gramEmojiId }, set: { store.gramEmojiId = $0 }),
                    TeleFlowMenu.offerEmojiRow(title: "Подарок 🎁", get: { store.giftEmojiId }, set: { store.giftEmojiId = $0 })
                ])
            ]
        })
    }

    private static func offerEmojiRow(title: String, get: @escaping () -> String, set: @escaping (String) -> Void) -> TeleFlowRow {
        return TeleFlowRow(title: title, kind: .link(icon: nil, color: nil, value: {
            let value = get()
            return value.isEmpty ? "не задан" : value
        }, action: { controller in
            let alert = UIAlertController(title: title, message: "Введи ID премиум-эмодзи или «* - ID». Пустое значение сбрасывает настройку.", preferredStyle: .alert)
            alert.addTextField { tf in
                tf.text = get()
                tf.placeholder = "* - 1234567890"
                tf.keyboardType = .numberPad
            }
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            alert.addAction(UIAlertAction(title: "Сохранить", style: .default, handler: { [weak alert, weak controller] _ in
                let text = alert?.textFields?.first?.text ?? ""
                set(String(text.filter { $0.isNumber }.prefix(32)))
                (controller as? TeleFlowListController)?.reload()
            }))
            controller.present(alert, animated: true)
        }))
    }

    private static func startOfferDraft(controller: UIViewController) {
        let alert = UIAlertController(title: "Шаг 1 из 4", message: "Для кого этот локальный черновик? Введи @юзернейм или числовой ID. Ничего не отправляется.", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "@username или ID"
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Далее", style: .default, handler: { [weak alert, weak controller] _ in
            let recipient = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !recipient.isEmpty, let controller = controller else {
                return
            }
            TeleFlowMenu.askOfferNFTLink(recipient: recipient, controller: controller)
        }))
        controller.present(alert, animated: true)
    }

    private static func askOfferNFTLink(recipient: String, controller: UIViewController) {
        let alert = UIAlertController(title: "Шаг 2 из 4", message: "Вставь официальную ссылку на NFT вида https://t.me/nft/…", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "https://t.me/nft/…"
            if let clipboard = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines), clipboard.lowercased().contains("t.me/nft/") {
                tf.text = clipboard
            }
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Далее", style: .default, handler: { [weak alert, weak controller] _ in
            let raw = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            var link = raw
            if link.lowercased().hasPrefix("t.me/nft/") {
                link = "https://" + link
            }
            guard link.lowercased().hasPrefix("https://t.me/nft/"), URL(string: link) != nil else {
                let error = UIAlertController(title: "Неверная NFT-ссылка", message: "Разрешена только официальная ссылка https://t.me/nft/…", preferredStyle: .alert)
                error.addAction(UIAlertAction(title: "Повторить", style: .default, handler: { _ in
                    if let controller = controller {
                        TeleFlowMenu.askOfferNFTLink(recipient: recipient, controller: controller)
                    }
                }))
                error.addAction(UIAlertAction(title: "Отмена", style: .cancel))
                controller?.present(error, animated: true)
                return
            }
            if let controller = controller {
                TeleFlowMenu.askOfferAmount(recipient: recipient, nftLink: link, controller: controller)
            }
        }))
        controller.present(alert, animated: true)
    }

    private static func askOfferAmount(recipient: String, nftLink: String, controller: UIViewController) {
        let alert = UIAlertController(title: "Шаг 3 из 4", message: "Сумма внутренних игровых единиц: gram 3–1 000 000, звёзды 125–1 000 000. До 125 валюта выбирается как gram автоматически.", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Сумма"
            tf.keyboardType = .numberPad
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Далее", style: .default, handler: { [weak alert, weak controller] _ in
            guard let text = alert?.textFields?.first?.text, let amount = Int64(text), amount > 0, amount <= 1_000_000 else {
                TeleFlowMenu.showOfferAmountError(recipient: recipient, nftLink: nftLink, controller: controller)
                return
            }
            if amount < 125 {
                guard amount >= 3 else {
                    TeleFlowMenu.showOfferAmountError(recipient: recipient, nftLink: nftLink, controller: controller)
                    return
                }
                if let controller = controller {
                    TeleFlowMenu.askOfferLanguage(recipient: recipient, nftLink: nftLink, amount: amount, currency: .gram, controller: controller)
                }
                return
            }
            let currencyAlert = UIAlertController(title: "Валюта черновика", message: "Выбери внутренние игровые единицы. Это не Telegram Stars.", preferredStyle: .actionSheet)
            currencyAlert.addAction(UIAlertAction(title: "Граммы", style: .default, handler: { _ in
                if let controller = controller {
                    TeleFlowMenu.askOfferLanguage(recipient: recipient, nftLink: nftLink, amount: amount, currency: .gram, controller: controller)
                }
            }))
            currencyAlert.addAction(UIAlertAction(title: "Звёзды", style: .default, handler: { _ in
                if let controller = controller {
                    TeleFlowMenu.askOfferLanguage(recipient: recipient, nftLink: nftLink, amount: amount, currency: .stars, controller: controller)
                }
            }))
            currencyAlert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            controller?.present(currencyAlert, animated: true)
        }))
        controller.present(alert, animated: true)
    }

    private static func showOfferAmountError(recipient: String, nftLink: String, controller: UIViewController?) {
        let alert = UIAlertController(title: "Неверная сумма", message: "Для gram: 3–1 000 000. Для звёзд: 125–1 000 000.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Повторить", style: .default, handler: { _ in
            if let controller = controller {
                TeleFlowMenu.askOfferAmount(recipient: recipient, nftLink: nftLink, controller: controller)
            }
        }))
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        controller?.present(alert, animated: true)
    }

    private static func askOfferLanguage(recipient: String, nftLink: String, amount: Int64, currency: TeleFlowOfferCurrency, controller: UIViewController) {
        let alert = UIAlertController(title: "Шаг 4 из 4", message: "Язык текста локального черновика", preferredStyle: .actionSheet)
        for language in TeleFlowOfferLanguage.allCases {
            alert.addAction(UIAlertAction(title: language.title, style: .default, handler: { _ in
                let draft = TeleFlowOfferStore.shared.addDraft(recipient: recipient, nftLink: nftLink, amount: amount, currency: currency, language: language)
                controller.navigationController?.pushViewController(TeleFlowOfferPreviewController(draft: draft), animated: true)
            }))
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        controller.present(alert, animated: true)
    }
}

// MARK: - Clearly marked local preview

final class TeleFlowOfferPreviewController: UIViewController {
    private let draft: TeleFlowOfferDraft
    private let gradientLayer = CAGradientLayer()
    private let scrollView = UIScrollView()
    private let cardView = UIView()
    private let watermarkLabel = UILabel()
    private let giftLabel = UILabel()
    private let nameLabel = UILabel()
    private let bodyLabel = UILabel()
    private let recipientLabel = UILabel()
    private let disclosureLabel = UILabel()
    private let emojiIdsLabel = UILabel()
    private let nftButton = UIButton(type: .system)

    init(draft: TeleFlowOfferDraft) {
        self.draft = draft
        super.init(nibName: nil, bundle: nil)
        self.title = "Локальный черновик"
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(red: 0.015, green: 0.025, blue: 0.075, alpha: 1.0)
        self.gradientLayer.colors = [
            UIColor(red: 0.02, green: 0.04, blue: 0.16, alpha: 1.0).cgColor,
            UIColor(red: 0.03, green: 0.10, blue: 0.28, alpha: 1.0).cgColor,
            UIColor(red: 0.01, green: 0.02, blue: 0.07, alpha: 1.0).cgColor
        ]
        self.gradientLayer.locations = [0.0, 0.55, 1.0]
        self.view.layer.insertSublayer(self.gradientLayer, at: 0)
        self.view.addSubview(self.scrollView)
        self.scrollView.addSubview(self.cardView)
        self.cardView.backgroundColor = UIColor(red: 0.035, green: 0.065, blue: 0.16, alpha: 0.96)
        self.cardView.layer.cornerRadius = 22.0
        self.cardView.layer.borderWidth = 1.0
        self.cardView.layer.borderColor = UIColor(red: 0.15, green: 0.30, blue: 0.58, alpha: 1.0).cgColor

        self.watermarkLabel.text = "ЛОКАЛЬНЫЙ ЧЕРНОВИК · НЕ ОТПРАВЛЕНО"
        self.watermarkLabel.textColor = .systemOrange
        self.watermarkLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .bold)
        self.watermarkLabel.textAlignment = .center
        self.watermarkLabel.numberOfLines = 0

        self.giftLabel.text = "🎁"
        self.giftLabel.font = UIFont.systemFont(ofSize: 84.0)
        self.giftLabel.textAlignment = .center

        self.nameLabel.text = self.draft.giftName
        self.nameLabel.textColor = .white
        self.nameLabel.font = UIFont.systemFont(ofSize: 22.0, weight: .bold)
        self.nameLabel.textAlignment = .center
        self.nameLabel.numberOfLines = 0

        self.bodyLabel.text = self.draft.localizedText
        self.bodyLabel.textColor = .white
        self.bodyLabel.font = UIFont.systemFont(ofSize: 18.0, weight: .medium)
        self.bodyLabel.numberOfLines = 0
        self.bodyLabel.textAlignment = self.draft.language == .ar ? .right : .natural
        if self.draft.language == .ar {
            self.bodyLabel.semanticContentAttribute = .forceRightToLeft
        }

        self.recipientLabel.text = "Черновик для: \(self.draft.recipient) · язык: \(self.draft.language.rawValue)"
        self.recipientLabel.textColor = .lightGray
        self.recipientLabel.font = UIFont.systemFont(ofSize: 14.0)
        self.recipientLabel.textAlignment = .center
        self.recipientLabel.numberOfLines = 0

        self.disclosureLabel.text = "Внутренние игровые единицы — не Telegram Stars.\nПредложение не отправлено, сделка не создана, NFT не передан.\nЛюбая реальная передача выполняется только владельцем через официальный интерфейс Telegram после независимой проверки условий и получателя."
        self.disclosureLabel.textColor = UIColor(white: 0.78, alpha: 1.0)
        self.disclosureLabel.font = UIFont.systemFont(ofSize: 13.0)
        self.disclosureLabel.textAlignment = .center
        self.disclosureLabel.numberOfLines = 0

        let store = TeleFlowOfferStore.shared
        self.emojiIdsLabel.text = "Premium emoji ID — ⭐: \(store.starEmojiId.isEmpty ? "—" : store.starEmojiId) · gram: \(store.gramEmojiId.isEmpty ? "—" : store.gramEmojiId) · 🎁: \(store.giftEmojiId.isEmpty ? "—" : store.giftEmojiId)"
        self.emojiIdsLabel.textColor = .systemGray
        self.emojiIdsLabel.font = UIFont.systemFont(ofSize: 11.0)
        self.emojiIdsLabel.textAlignment = .center
        self.emojiIdsLabel.numberOfLines = 0

        self.nftButton.setTitle("Открыть официальную NFT-ссылку", for: .normal)
        self.nftButton.setTitleColor(.white, for: .normal)
        self.nftButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .semibold)
        self.nftButton.backgroundColor = .systemBlue
        self.nftButton.layer.cornerRadius = 12.0
        self.nftButton.addTarget(self, action: #selector(self.openOfficialNFT), for: .touchUpInside)

        let cardSubviews: [UIView] = [self.watermarkLabel, self.giftLabel, self.nameLabel, self.bodyLabel, self.recipientLabel, self.disclosureLabel, self.emojiIdsLabel, self.nftButton]
        for view in cardSubviews {
            self.cardView.addSubview(view)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.gradientLayer.frame = self.view.bounds
        self.scrollView.frame = self.view.bounds
        let horizontalInset: CGFloat = 18.0
        let cardWidth = min(440.0, self.view.bounds.width - horizontalInset * 2.0)
        let cardX = (self.view.bounds.width - cardWidth) * 0.5
        let cardY = self.view.safeAreaInsets.top + 18.0
        let cardHeight: CGFloat = 590.0
        self.cardView.frame = CGRect(x: cardX, y: cardY, width: cardWidth, height: cardHeight)
        let innerWidth = cardWidth - 32.0
        self.watermarkLabel.frame = CGRect(x: 16.0, y: 16.0, width: innerWidth, height: 40.0)
        self.giftLabel.frame = CGRect(x: 16.0, y: 62.0, width: innerWidth, height: 104.0)
        self.nameLabel.frame = CGRect(x: 16.0, y: 172.0, width: innerWidth, height: 56.0)
        self.bodyLabel.frame = CGRect(x: 16.0, y: 236.0, width: innerWidth, height: 100.0)
        self.recipientLabel.frame = CGRect(x: 16.0, y: 340.0, width: innerWidth, height: 40.0)
        self.disclosureLabel.frame = CGRect(x: 16.0, y: 386.0, width: innerWidth, height: 94.0)
        self.emojiIdsLabel.frame = CGRect(x: 16.0, y: 484.0, width: innerWidth, height: 42.0)
        self.nftButton.frame = CGRect(x: 16.0, y: 532.0, width: innerWidth, height: 44.0)
        self.scrollView.contentSize = CGSize(width: self.view.bounds.width, height: cardY + cardHeight + 24.0)
    }

    @objc private func openOfficialNFT() {
        guard let url = URL(string: self.draft.nftLink) else {
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

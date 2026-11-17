import Foundation

/// Local, visual-only gift showcase: everything here exists only on this device,
/// inside the TeleFlow menu. It is never sent anywhere and does not change any
/// real Telegram data.
public enum TeleFlowLocalCurrency: String, Codable {
    case stars
    case gram

    public var symbol: String {
        switch self {
        case .stars:
            return "⭐"
        case .gram:
            return "G"
        }
    }

    public var title: String {
        switch self {
        case .stars:
            return "звёзды"
        case .gram:
            return "gram"
        }
    }
}

public enum TeleFlowGiftKind: String, Codable {
    case ordinary
    case nft
}

public struct TeleFlowShowcaseGift: Codable, Equatable {
    public let uid: String
    public let name: String
    public let emoji: String
    public let priceGram: Int64
    public let priceStars: Int64
    public var upgraded: Bool
    public var crafted: Bool
    /// Currency used to acquire this local gift; nil for archived/crafted cards.
    public var acquiredCurrency: TeleFlowLocalCurrency?
    /// Marks the gift as "pinned" into the visual profile section of the showcase.
    public var inProfile: Bool
    /// A user-added archived/delisted gift card, not a market purchase.
    public var archived: Bool
    public var kind: TeleFlowGiftKind
    public var nftLink: String
    public var giftNumber: String

    enum CodingKeys: String, CodingKey {
        case uid
        case name
        case emoji
        case priceGram
        case priceStars
        case upgraded
        case crafted
        case acquiredCurrency
        case inProfile
        case archived
        case kind
        case nftLink
        case giftNumber
    }

    public init(uid: String, name: String, emoji: String, priceGram: Int64, priceStars: Int64? = nil, upgraded: Bool = false, crafted: Bool = false, acquiredCurrency: TeleFlowLocalCurrency? = nil, inProfile: Bool = false, archived: Bool = false, kind: TeleFlowGiftKind = .nft, nftLink: String = "", giftNumber: String = "") {
        self.uid = uid
        self.name = name
        self.emoji = emoji
        self.priceGram = max(0, priceGram)
        self.priceStars = max(0, priceStars ?? priceGram)
        self.upgraded = upgraded
        self.crafted = crafted
        self.acquiredCurrency = acquiredCurrency
        self.inProfile = inProfile
        self.archived = archived
        self.kind = kind
        self.nftLink = nftLink
        self.giftNumber = giftNumber
    }

    public func price(for currency: TeleFlowLocalCurrency) -> Int64 {
        switch currency {
        case .stars:
            return self.priceStars
        case .gram:
            return self.priceGram
        }
    }

    /// Tolerates showcases stored by older builds (without `inProfile`).
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uid = try container.decode(String.self, forKey: .uid)
        self.name = try container.decode(String.self, forKey: .name)
        self.emoji = try container.decode(String.self, forKey: .emoji)
        self.priceGram = max(0, try container.decode(Int64.self, forKey: .priceGram))
        self.priceStars = max(0, try container.decodeIfPresent(Int64.self, forKey: .priceStars) ?? self.priceGram)
        self.upgraded = try container.decodeIfPresent(Bool.self, forKey: .upgraded) ?? false
        self.crafted = try container.decodeIfPresent(Bool.self, forKey: .crafted) ?? false
        self.acquiredCurrency = try container.decodeIfPresent(TeleFlowLocalCurrency.self, forKey: .acquiredCurrency)
        self.inProfile = try container.decodeIfPresent(Bool.self, forKey: .inProfile) ?? false
        self.archived = try container.decodeIfPresent(Bool.self, forKey: .archived) ?? false
        self.kind = try container.decodeIfPresent(TeleFlowGiftKind.self, forKey: .kind) ?? .nft
        self.nftLink = try container.decodeIfPresent(String.self, forKey: .nftLink) ?? ""
        self.giftNumber = try container.decodeIfPresent(String.self, forKey: .giftNumber) ?? ""
    }
}

/// A local record of a visual gift or gram transfer inside the mod menu.
/// Nothing is actually sent to anyone — this is a personal ledger on this device.
public struct TeleFlowTransferRecord: Codable, Equatable {
    public let uid: String
    public let emoji: String
    public let title: String
    public let recipientName: String
    public let recipientId: Int64
    public let amount: Int64
    public let isGram: Bool
    public let paymentCurrency: TeleFlowLocalCurrency?
    public let date: TimeInterval
    public let giftUid: String?
    public let upgraded: Bool
    public let crafted: Bool
    public let isNFT: Bool

    enum CodingKeys: String, CodingKey {
        case uid
        case emoji
        case title
        case recipientName
        case recipientId
        case amount
        case isGram
        case paymentCurrency
        case date
        case giftUid
        case upgraded
        case crafted
        case isNFT
    }

    public init(uid: String, emoji: String, title: String, recipientName: String, recipientId: Int64, amount: Int64, isGram: Bool, date: TimeInterval, paymentCurrency: TeleFlowLocalCurrency? = nil, giftUid: String? = nil, upgraded: Bool = false, crafted: Bool = false, isNFT: Bool = false) {
        self.uid = uid
        self.emoji = emoji
        self.title = title
        self.recipientName = recipientName
        self.recipientId = recipientId
        self.amount = amount
        self.isGram = isGram
        self.paymentCurrency = paymentCurrency
        self.date = date
        self.giftUid = giftUid
        self.upgraded = upgraded
        self.crafted = crafted
        self.isNFT = isNFT
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uid = try container.decode(String.self, forKey: .uid)
        self.emoji = try container.decode(String.self, forKey: .emoji)
        self.title = try container.decode(String.self, forKey: .title)
        self.recipientName = try container.decode(String.self, forKey: .recipientName)
        self.recipientId = try container.decode(Int64.self, forKey: .recipientId)
        self.amount = try container.decode(Int64.self, forKey: .amount)
        self.isGram = try container.decode(Bool.self, forKey: .isGram)
        self.paymentCurrency = try container.decodeIfPresent(TeleFlowLocalCurrency.self, forKey: .paymentCurrency)
        self.date = try container.decode(TimeInterval.self, forKey: .date)
        self.giftUid = try container.decodeIfPresent(String.self, forKey: .giftUid)
        self.upgraded = try container.decodeIfPresent(Bool.self, forKey: .upgraded) ?? false
        self.crafted = try container.decodeIfPresent(Bool.self, forKey: .crafted) ?? false
        self.isNFT = try container.decodeIfPresent(Bool.self, forKey: .isNFT) ?? !self.isGram
    }
}

public enum TeleFlowGramTransactionKind: String, Codable {
    case topUp
    case adjustment
    case purchase
    case gift
    case transfer
}

/// One entry in the local gram balance history. A negative amount is a visual
/// spend, a positive amount is a visual top-up. No real currency is involved.
public struct TeleFlowGramTransaction: Codable, Equatable {
    public let uid: String
    public let kind: TeleFlowGramTransactionKind
    public let title: String
    public let recipientName: String
    public let recipientId: Int64
    public let amount: Int64
    public let balanceAfter: Int64
    public let date: TimeInterval
    public let currency: TeleFlowLocalCurrency

    enum CodingKeys: String, CodingKey {
        case uid
        case kind
        case title
        case recipientName
        case recipientId
        case amount
        case balanceAfter
        case date
        case currency
    }

    public init(uid: String, kind: TeleFlowGramTransactionKind, title: String, recipientName: String, recipientId: Int64, amount: Int64, balanceAfter: Int64, date: TimeInterval, currency: TeleFlowLocalCurrency = .gram) {
        self.uid = uid
        self.kind = kind
        self.title = title
        self.recipientName = recipientName
        self.recipientId = recipientId
        self.amount = amount
        self.balanceAfter = balanceAfter
        self.date = date
        self.currency = currency
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uid = try container.decode(String.self, forKey: .uid)
        self.kind = try container.decode(TeleFlowGramTransactionKind.self, forKey: .kind)
        self.title = try container.decode(String.self, forKey: .title)
        self.recipientName = try container.decode(String.self, forKey: .recipientName)
        self.recipientId = try container.decode(Int64.self, forKey: .recipientId)
        self.amount = try container.decode(Int64.self, forKey: .amount)
        self.balanceAfter = try container.decode(Int64.self, forKey: .balanceAfter)
        self.date = try container.decode(TimeInterval.self, forKey: .date)
        self.currency = try container.decodeIfPresent(TeleFlowLocalCurrency.self, forKey: .currency) ?? .gram
    }
}

public final class TeleFlowGiftStore {
    public static let shared = TeleFlowGiftStore()

    private let key = "teleflow.showcaseGifts"
    private let transfersKey = "teleflow.transfers"
    private let transactionsKey = "teleflow.gramTransactions"

    private var gifts: [TeleFlowShowcaseGift] {
        get {
            if let data = UserDefaults.standard.data(forKey: self.key), let decoded = try? JSONDecoder().decode([TeleFlowShowcaseGift].self, from: data) {
                return decoded
            }
            return []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: self.key)
            }
        }
    }

    private var transfers: [TeleFlowTransferRecord] {
        get {
            if let data = UserDefaults.standard.data(forKey: self.transfersKey), let decoded = try? JSONDecoder().decode([TeleFlowTransferRecord].self, from: data) {
                return decoded
            }
            return []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: self.transfersKey)
            }
        }
    }

    private var transactions: [TeleFlowGramTransaction] {
        get {
            if let data = UserDefaults.standard.data(forKey: self.transactionsKey), let decoded = try? JSONDecoder().decode([TeleFlowGramTransaction].self, from: data) {
                return decoded
            }
            return []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: self.transactionsKey)
            }
        }
    }

    private init() {
    }

    public var count: Int {
        return self.gifts.count
    }

    public var all: [TeleFlowShowcaseGift] {
        return self.gifts
    }

    public var profileGifts: [TeleFlowShowcaseGift] {
        return self.gifts.filter { $0.inProfile }
    }

    /// A compact emoji summary for the local profile-header gift pill. Your own
    /// profile shows pinned showcase gifts; another profile shows gifts visually
    /// sent to that peer from this device.
    public func profileGiftSummary(peerId: Int64, isMyProfile: Bool) -> String {
        let emojis: [String]
        if isMyProfile {
            // Pinned owned gifts and the local outgoing-gift activity both belong
            // to the sender's on-device profile view.
            emojis = self.profileGifts.map { $0.emoji } + self.transfers.filter {
                !$0.isGram && $0.recipientId != TeleFlowSettings.shared.accountId
            }.map { $0.emoji }
        } else {
            emojis = self.transfers.filter { !$0.isGram && $0.recipientId == peerId }.map { $0.emoji }
        }
        guard !emojis.isEmpty else {
            return ""
        }
        let visible = emojis.prefix(3).joined()
        let remaining = emojis.count - 3
        return remaining > 0 ? visible + " +\(remaining)" : visible
    }

    public var transferCount: Int {
        return self.transfers.count
    }

    public var allTransfers: [TeleFlowTransferRecord] {
        return Array(self.transfers.reversed())
    }

    public func profileTransfers(peerId: Int64, isMyProfile: Bool) -> [TeleFlowTransferRecord] {
        return self.allTransfers.filter { transfer in
            guard !transfer.isGram else {
                return false
            }
            if isMyProfile {
                return transfer.recipientId != TeleFlowSettings.shared.accountId
            }
            return peerId != 0 && transfer.recipientId == peerId
        }
    }

    public var transactionCount: Int {
        return self.transactions.count
    }

    public func transactionCount(currency: TeleFlowLocalCurrency) -> Int {
        return self.transactions.filter { $0.currency == currency }.count
    }

    public var allTransactions: [TeleFlowGramTransaction] {
        return Array(self.transactions.reversed())
    }

    public func transactions(currency: TeleFlowLocalCurrency) -> [TeleFlowGramTransaction] {
        return Array(self.transactions.filter { $0.currency == currency }.reversed())
    }

    /// Ordinary, non-collectible gifts for the separate local sending flow.
    public static let ordinaryCatalog: [TeleFlowShowcaseGift] = [
        TeleFlowShowcaseGift(uid: "ordinary.heart", name: "Heart", emoji: "❤️", priceGram: 15, kind: .ordinary),
        TeleFlowShowcaseGift(uid: "ordinary.rose", name: "Rose", emoji: "🌹", priceGram: 25, kind: .ordinary),
        TeleFlowShowcaseGift(uid: "ordinary.giftbox", name: "Gift Box", emoji: "🎁", priceGram: 25, kind: .ordinary),
        TeleFlowShowcaseGift(uid: "ordinary.bouquet", name: "Bouquet", emoji: "💐", priceGram: 50, kind: .ordinary),
        TeleFlowShowcaseGift(uid: "ordinary.rocket", name: "Rocket", emoji: "🚀", priceGram: 50, kind: .ordinary),
        TeleFlowShowcaseGift(uid: "ordinary.champagne", name: "Champagne", emoji: "🍾", priceGram: 50, kind: .ordinary),
        TeleFlowShowcaseGift(uid: "ordinary.ring", name: "Ring", emoji: "💍", priceGram: 100, kind: .ordinary),
        TeleFlowShowcaseGift(uid: "ordinary.teddybear", name: "Teddy Bear", emoji: "🧸", priceGram: 100, kind: .ordinary),
        TeleFlowShowcaseGift(uid: "ordinary.cake", name: "Delicate Cake", emoji: "🎂", priceGram: 150, kind: .ordinary),
        TeleFlowShowcaseGift(uid: "ordinary.trophy", name: "Trophy", emoji: "🏆", priceGram: 250, kind: .ordinary)
    ]

    /// The catalog shown in the market screen: classic Telegram collectible gift names
    /// with independent visual prices in local stars and gram.
    public static let catalog: [TeleFlowShowcaseGift] = [
        TeleFlowShowcaseGift(uid: "cat.plushpepe", name: "Plush Pepe", emoji: "🐸", priceGram: 900),
        TeleFlowShowcaseGift(uid: "cat.durovscap", name: "Durov's Cap", emoji: "🧢", priceGram: 800),
        TeleFlowShowcaseGift(uid: "cat.preciouspeach", name: "Precious Peach", emoji: "🍑", priceGram: 750),
        TeleFlowShowcaseGift(uid: "cat.vintagecigar", name: "Vintage Cigar", emoji: "🚬", priceGram: 700),
        TeleFlowShowcaseGift(uid: "cat.jesterhat", name: "Jester Hat", emoji: "🃏", priceGram: 650),
        TeleFlowShowcaseGift(uid: "cat.magicpotion", name: "Magic Potion", emoji: "🧪", priceGram: 600),
        TeleFlowShowcaseGift(uid: "cat.sharptongue", name: "Sharp Tongue", emoji: "👅", priceGram: 550),
        TeleFlowShowcaseGift(uid: "cat.skullflower", name: "Skull Flower", emoji: "💀", priceGram: 500),
        TeleFlowShowcaseGift(uid: "cat.scaredcat", name: "Scared Cat", emoji: "🐱", priceGram: 450),
        TeleFlowShowcaseGift(uid: "cat.hitrust", name: "Hex Pot", emoji: "🔮", priceGram: 400),
        TeleFlowShowcaseGift(uid: "cat.evieleye", name: "Evil Eye", emoji: "🧿", priceGram: 350),
        TeleFlowShowcaseGift(uid: "cat.legendarytree", name: "Legendary Tree", emoji: "🎄", priceGram: 300),
        TeleFlowShowcaseGift(uid: "cat.crystalball", name: "Crystal Ball", emoji: "💎", priceGram: 250),
        TeleFlowShowcaseGift(uid: "cat.jellybunny", name: "Jelly Bunny", emoji: "🐰", priceGram: 200),
        TeleFlowShowcaseGift(uid: "cat.sleighbell", name: "Sleigh Bell", emoji: "🔔", priceGram: 150),
        TeleFlowShowcaseGift(uid: "cat.gingercookie", name: "Ginger Cookie", emoji: "🍪", priceGram: 120),
        TeleFlowShowcaseGift(uid: "cat.winterwreath", name: "Winter Wreath", emoji: "🎅", priceGram: 100),
        TeleFlowShowcaseGift(uid: "cat.jawbreaker", name: "Jawbreaker", emoji: "🍬", priceGram: 80),
        TeleFlowShowcaseGift(uid: "cat.spyingghost", name: "Spying Ghost", emoji: "👻", priceGram: 60),
        TeleFlowShowcaseGift(uid: "cat.tamagotchi", name: "Tama Gadget", emoji: "📱", priceGram: 50)
    ]

    public func add(_ catalogGift: TeleFlowShowcaseGift) -> Bool {
        var current = self.gifts
        let uid = catalogGift.uid + "." + String(UUID().uuidString.prefix(6))
        current.append(TeleFlowShowcaseGift(uid: uid, name: catalogGift.name, emoji: catalogGift.emoji, priceGram: catalogGift.priceGram, priceStars: catalogGift.priceStars, upgraded: catalogGift.upgraded, crafted: catalogGift.crafted, acquiredCurrency: catalogGift.acquiredCurrency, inProfile: catalogGift.inProfile, archived: catalogGift.archived, kind: catalogGift.kind, nftLink: catalogGift.nftLink, giftNumber: catalogGift.giftNumber))
        self.gifts = current
        return true
    }

    /// Adds a local card for a delisted or otherwise unavailable NFT gift. It is
    /// immediately pinned to the visual profile and can be upgraded like other gifts.
    @discardableResult
    public func addArchived(name: String, emoji: String, nftLink: String, giftNumber: String) -> TeleFlowShowcaseGift {
        let gift = TeleFlowShowcaseGift(
            uid: "archived." + String(UUID().uuidString.prefix(8)),
            name: name,
            emoji: emoji.isEmpty ? "🎁" : emoji,
            priceGram: 0,
            inProfile: true,
            archived: true,
            nftLink: nftLink,
            giftNumber: giftNumber
        )
        var current = self.gifts
        current.append(gift)
        self.gifts = current
        return gift
    }

    /// Visually sends a gift to your own profile without removing it from the showcase.
    public func sendToProfile(uid: String) {
        guard let gift = self.gifts.first(where: { $0.uid == uid }) else {
            return
        }
        self.setInProfile(uid: uid, inProfile: true)
        self.appendTransfer(emoji: gift.emoji, title: gift.name, recipientName: "Мой профиль", recipientId: TeleFlowSettings.shared.accountId, amount: 0, isGram: false, giftUid: gift.uid, upgraded: gift.upgraded, crafted: gift.crafted, isNFT: gift.kind == .nft)
    }

    public func setUpgraded(uid: String, upgraded: Bool) {
        var current = self.gifts
        if let index = current.firstIndex(where: { $0.uid == uid }), current[index].kind == .nft || !upgraded {
            current[index].upgraded = upgraded
            self.gifts = current
        }
    }

    @discardableResult
    public func upgrade(uid: String) -> Bool {
        guard let gift = self.gifts.first(where: { $0.uid == uid }), gift.kind == .nft, !gift.upgraded else {
            return false
        }
        self.setUpgraded(uid: uid, upgraded: true)
        return true
    }

    /// Atomically combines two upgraded local NFT cards. No Telegram craft request
    /// or blockchain operation is performed.
    public func craft(firstUid: String, secondUid: String) -> TeleFlowShowcaseGift? {
        var current = self.gifts
        guard firstUid != secondUid,
              let firstIndex = current.firstIndex(where: { $0.uid == firstUid }),
              let secondIndex = current.firstIndex(where: { $0.uid == secondUid }) else {
            return nil
        }
        let first = current[firstIndex]
        let second = current[secondIndex]
        guard first.kind == .nft, second.kind == .nft, first.upgraded, second.upgraded else {
            return nil
        }
        func craftedPrice(_ lhs: Int64, _ rhs: Int64) -> Int64 {
            let base = lhs / 2 + rhs / 2
            let (value, overflow) = base.addingReportingOverflow(20)
            return max(10, overflow ? Int64.max : value)
        }
        let crafted = TeleFlowShowcaseGift(
            uid: "crafted." + String(UUID().uuidString.prefix(8)),
            name: "\(first.name) + \(second.name)",
            emoji: "🎁",
            priceGram: craftedPrice(first.priceGram, second.priceGram),
            priceStars: craftedPrice(first.priceStars, second.priceStars),
            upgraded: true,
            crafted: true,
            inProfile: first.inProfile || second.inProfile,
            kind: .nft
        )
        current.removeAll { $0.uid == firstUid || $0.uid == secondUid }
        current.append(crafted)
        self.gifts = current
        return crafted
    }

    public func setInProfile(uid: String, inProfile: Bool) {
        var current = self.gifts
        if let index = current.firstIndex(where: { $0.uid == uid }) {
            current[index].inProfile = inProfile
            self.gifts = current
        }
    }

    // MARK: Local gram operations and history

    /// Sets the visual balance and records the difference as a top-up or adjustment.
    @discardableResult
    public func setLocalGramBalance(_ value: Int64) -> Int64 {
        let settings = TeleFlowSettings.shared
        let previous = settings.localGramValue
        let updated = max(0, value)
        guard updated != previous else {
            return updated
        }
        settings.localGramValue = updated
        let delta = updated - previous
        self.appendTransaction(kind: delta > 0 ? .topUp : .adjustment, title: delta > 0 ? "Пополнение баланса" : "Изменение баланса", recipientName: "", recipientId: 0, amount: delta)
        return updated
    }

    /// Adds a positive amount to the visual balance and writes a top-up entry.
    @discardableResult
    public func topUpLocalGram(_ amount: Int64) -> Bool {
        guard amount > 0 else {
            return false
        }
        let (updated, overflow) = TeleFlowSettings.shared.localGramValue.addingReportingOverflow(amount)
        guard !overflow else {
            return false
        }
        TeleFlowSettings.shared.localGramValue = updated
        self.appendTransaction(kind: .topUp, title: "Пополнение баланса", recipientName: "", recipientId: 0, amount: amount)
        return true
    }

    @discardableResult
    public func setLocalStarsBalance(_ value: Int64) -> Int64 {
        let settings = TeleFlowSettings.shared
        let previous = settings.localStarsValue
        let updated = max(0, value)
        guard updated != previous else {
            return updated
        }
        settings.localStarsValue = updated
        let delta = updated - previous
        self.appendTransaction(kind: delta > 0 ? .topUp : .adjustment, title: delta > 0 ? "Пополнение баланса" : "Изменение баланса", recipientName: "", recipientId: 0, amount: delta, currency: .stars)
        return updated
    }

    @discardableResult
    public func topUpLocalStars(_ amount: Int64) -> Bool {
        guard amount > 0 else {
            return false
        }
        let (updated, overflow) = TeleFlowSettings.shared.localStarsValue.addingReportingOverflow(amount)
        guard !overflow else {
            return false
        }
        TeleFlowSettings.shared.localStarsValue = updated
        self.appendTransaction(kind: .topUp, title: "Пополнение баланса", recipientName: "", recipientId: 0, amount: amount, currency: .stars)
        return true
    }

    public func balance(currency: TeleFlowLocalCurrency) -> Int64 {
        switch currency {
        case .stars:
            return TeleFlowSettings.shared.localStarsValue
        case .gram:
            return TeleFlowSettings.shared.localGramValue
        }
    }

    private func debit(_ amount: Int64, currency: TeleFlowLocalCurrency) {
        switch currency {
        case .stars:
            TeleFlowSettings.shared.addLocalStars(-amount)
        case .gram:
            TeleFlowSettings.shared.addLocalGram(-amount)
        }
    }

    /// Buys a catalog gift into the local showcase and records the visual spend
    /// in the selected local currency.
    @discardableResult
    public func purchase(_ gift: TeleFlowShowcaseGift, currency: TeleFlowLocalCurrency = .gram) -> Bool {
        let price = gift.price(for: currency)
        guard price >= 0, self.balance(currency: currency) >= price else {
            return false
        }
        self.debit(price, currency: currency)
        var ownedGift = gift
        ownedGift.acquiredCurrency = currency
        _ = self.add(ownedGift)
        self.appendTransaction(kind: .purchase, title: "Покупка: \(gift.emoji) \(gift.name)", recipientName: "", recipientId: 0, amount: -price, currency: currency)
        return true
    }

    /// Visually sends a catalog gift directly to a chat recipient. The selected
    /// local currency is deducted and the operation appears in both journals.
    @discardableResult
    public func giftCatalogGift(_ gift: TeleFlowShowcaseGift, recipientName: String, recipientId: Int64, currency: TeleFlowLocalCurrency = .gram) -> Bool {
        let price = gift.price(for: currency)
        guard !recipientName.isEmpty, price >= 0, self.balance(currency: currency) >= price else {
            return false
        }
        self.debit(price, currency: currency)
        self.appendTransfer(emoji: gift.emoji, title: gift.name, recipientName: recipientName, recipientId: recipientId, amount: price, isGram: false, paymentCurrency: currency, giftUid: gift.uid, upgraded: gift.upgraded, crafted: gift.crafted, isNFT: gift.kind == .nft)
        self.appendTransaction(kind: .gift, title: "Подарок: \(gift.emoji) \(gift.name)", recipientName: recipientName, recipientId: recipientId, amount: -price, currency: currency)
        return true
    }

    /// Removes a showcase gift and writes a visual transfer record. Its purchase price
    /// was already paid when it entered the showcase, so no second debit is made.
    public func giftAway(uid: String, recipientName: String, recipientId: Int64) {
        var current = self.gifts
        guard let index = current.firstIndex(where: { $0.uid == uid }) else {
            return
        }
        let gift = current.remove(at: index)
        self.gifts = current
        let paymentCurrency = gift.acquiredCurrency ?? (gift.crafted || gift.archived ? nil : TeleFlowLocalCurrency.gram)
        let paidPrice = paymentCurrency.map { gift.price(for: $0) } ?? 0
        self.appendTransfer(emoji: gift.emoji, title: gift.name, recipientName: recipientName, recipientId: recipientId, amount: paidPrice, isGram: false, paymentCurrency: paymentCurrency, giftUid: gift.uid, upgraded: gift.upgraded, crafted: gift.crafted, isNFT: gift.kind == .nft)
    }

    /// Debits visual gram and writes matching transfer and balance-history entries.
    @discardableResult
    public func recordGramTransfer(amount: Int64, recipientName: String, recipientId: Int64) -> Bool {
        let settings = TeleFlowSettings.shared
        guard amount > 0, !recipientName.isEmpty, settings.localGramValue >= amount else {
            return false
        }
        settings.addLocalGram(-amount)
        self.appendTransfer(emoji: "G", title: "Gram", recipientName: recipientName, recipientId: recipientId, amount: amount, isGram: true)
        self.appendTransaction(kind: .transfer, title: "Перевод gram", recipientName: recipientName, recipientId: recipientId, amount: -amount)
        return true
    }

    private func appendTransfer(emoji: String, title: String, recipientName: String, recipientId: Int64, amount: Int64, isGram: Bool, paymentCurrency: TeleFlowLocalCurrency? = nil, giftUid: String? = nil, upgraded: Bool = false, crafted: Bool = false, isNFT: Bool = false) {
        let record = TeleFlowTransferRecord(
            uid: "tr." + String(UUID().uuidString.prefix(8)),
            emoji: emoji,
            title: title,
            recipientName: recipientName,
            recipientId: recipientId,
            amount: amount,
            isGram: isGram,
            date: Date().timeIntervalSince1970,
            paymentCurrency: paymentCurrency,
            giftUid: giftUid,
            upgraded: upgraded,
            crafted: crafted,
            isNFT: isNFT
        )
        var records = self.transfers
        records.append(record)
        self.transfers = records
    }

    private func appendTransaction(kind: TeleFlowGramTransactionKind, title: String, recipientName: String, recipientId: Int64, amount: Int64, currency: TeleFlowLocalCurrency = .gram) {
        let record = TeleFlowGramTransaction(
            uid: "gr." + String(UUID().uuidString.prefix(8)),
            kind: kind,
            title: title,
            recipientName: recipientName,
            recipientId: recipientId,
            amount: amount,
            balanceAfter: self.balance(currency: currency),
            date: Date().timeIntervalSince1970,
            currency: currency
        )
        var records = self.transactions
        records.append(record)
        self.transactions = records
    }

    public func removeTransfer(uid: String) {
        var records = self.transfers
        records.removeAll { $0.uid == uid }
        self.transfers = records
    }

    public func removeAllTransfers() {
        self.transfers = []
    }

    public func removeTransactions(currency: TeleFlowLocalCurrency) {
        self.transactions = self.transactions.filter { $0.currency != currency }
    }

    public func removeAllTransactions() {
        self.transactions = []
    }

    public func remove(uid: String) {
        var current = self.gifts
        current.removeAll { $0.uid == uid }
        self.gifts = current
    }

    public func removeAll() {
        self.gifts = []
    }
}

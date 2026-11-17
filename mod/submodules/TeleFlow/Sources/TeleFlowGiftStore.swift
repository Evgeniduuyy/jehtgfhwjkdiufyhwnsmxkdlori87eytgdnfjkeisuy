import Foundation

/// Local, visual-only gift showcase: everything here exists only on this device,
/// inside the TeleFlow menu. It is never sent anywhere and does not change any
/// real Telegram data.
public struct TeleFlowShowcaseGift: Codable, Equatable {
    public let uid: String
    public let name: String
    public let emoji: String
    public let priceGram: Int64
    public var upgraded: Bool
    public var crafted: Bool
    /// Marks the gift as "pinned" into the visual profile section of the showcase.
    public var inProfile: Bool
    /// A user-added archived/delisted gift card, not a market purchase.
    public var archived: Bool
    public var nftLink: String
    public var giftNumber: String

    enum CodingKeys: String, CodingKey {
        case uid
        case name
        case emoji
        case priceGram
        case upgraded
        case crafted
        case inProfile
        case archived
        case nftLink
        case giftNumber
    }

    public init(uid: String, name: String, emoji: String, priceGram: Int64, upgraded: Bool = false, crafted: Bool = false, inProfile: Bool = false, archived: Bool = false, nftLink: String = "", giftNumber: String = "") {
        self.uid = uid
        self.name = name
        self.emoji = emoji
        self.priceGram = priceGram
        self.upgraded = upgraded
        self.crafted = crafted
        self.inProfile = inProfile
        self.archived = archived
        self.nftLink = nftLink
        self.giftNumber = giftNumber
    }

    /// Tolerates showcases stored by older builds (without `inProfile`).
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uid = try container.decode(String.self, forKey: .uid)
        self.name = try container.decode(String.self, forKey: .name)
        self.emoji = try container.decode(String.self, forKey: .emoji)
        self.priceGram = try container.decode(Int64.self, forKey: .priceGram)
        self.upgraded = try container.decodeIfPresent(Bool.self, forKey: .upgraded) ?? false
        self.crafted = try container.decodeIfPresent(Bool.self, forKey: .crafted) ?? false
        self.inProfile = try container.decodeIfPresent(Bool.self, forKey: .inProfile) ?? false
        self.archived = try container.decodeIfPresent(Bool.self, forKey: .archived) ?? false
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
    public let date: TimeInterval

    public init(uid: String, emoji: String, title: String, recipientName: String, recipientId: Int64, amount: Int64, isGram: Bool, date: TimeInterval) {
        self.uid = uid
        self.emoji = emoji
        self.title = title
        self.recipientName = recipientName
        self.recipientId = recipientId
        self.amount = amount
        self.isGram = isGram
        self.date = date
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

    public init(uid: String, kind: TeleFlowGramTransactionKind, title: String, recipientName: String, recipientId: Int64, amount: Int64, balanceAfter: Int64, date: TimeInterval) {
        self.uid = uid
        self.kind = kind
        self.title = title
        self.recipientName = recipientName
        self.recipientId = recipientId
        self.amount = amount
        self.balanceAfter = balanceAfter
        self.date = date
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
            emojis = self.profileGifts.map { $0.emoji }
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

    public var transactionCount: Int {
        return self.transactions.count
    }

    public var allTransactions: [TeleFlowGramTransaction] {
        return Array(self.transactions.reversed())
    }

    /// The catalog shown in the market screen: classic Telegram collectible gift names
    /// with their visual prices in gram.
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
        current.append(TeleFlowShowcaseGift(uid: uid, name: catalogGift.name, emoji: catalogGift.emoji, priceGram: catalogGift.priceGram, upgraded: catalogGift.upgraded, crafted: catalogGift.crafted, inProfile: catalogGift.inProfile, archived: catalogGift.archived, nftLink: catalogGift.nftLink, giftNumber: catalogGift.giftNumber))
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
        self.appendTransfer(emoji: gift.emoji, title: gift.name, recipientName: "Мой профиль", recipientId: TeleFlowSettings.shared.accountId, amount: 0, isGram: false)
    }

    public func setUpgraded(uid: String, upgraded: Bool) {
        var current = self.gifts
        if let index = current.firstIndex(where: { $0.uid == uid }) {
            current[index].upgraded = upgraded
            self.gifts = current
        }
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
        TeleFlowSettings.shared.addLocalGram(amount)
        self.appendTransaction(kind: .topUp, title: "Пополнение баланса", recipientName: "", recipientId: 0, amount: amount)
        return true
    }

    /// Buys a catalog gift into the local showcase and records the visual spend.
    @discardableResult
    public func purchase(_ gift: TeleFlowShowcaseGift) -> Bool {
        let settings = TeleFlowSettings.shared
        guard gift.priceGram >= 0, settings.localGramValue >= gift.priceGram else {
            return false
        }
        settings.addLocalGram(-gift.priceGram)
        _ = self.add(gift)
        self.appendTransaction(kind: .purchase, title: "Покупка: \(gift.emoji) \(gift.name)", recipientName: "", recipientId: 0, amount: -gift.priceGram)
        return true
    }

    /// Visually sends a catalog gift directly to a chat recipient. The price is
    /// deducted locally and the operation appears in both local journals.
    @discardableResult
    public func giftCatalogGift(_ gift: TeleFlowShowcaseGift, recipientName: String, recipientId: Int64) -> Bool {
        let settings = TeleFlowSettings.shared
        guard !recipientName.isEmpty, gift.priceGram >= 0, settings.localGramValue >= gift.priceGram else {
            return false
        }
        settings.addLocalGram(-gift.priceGram)
        self.appendTransfer(emoji: gift.emoji, title: gift.name, recipientName: recipientName, recipientId: recipientId, amount: gift.priceGram, isGram: false)
        self.appendTransaction(kind: .gift, title: "Подарок: \(gift.emoji) \(gift.name)", recipientName: recipientName, recipientId: recipientId, amount: -gift.priceGram)
        return true
    }

    /// Removes a showcase gift and writes a visual transfer record. Its gram price
    /// was already paid when it entered the showcase, so no second debit is made.
    public func giftAway(uid: String, recipientName: String, recipientId: Int64) {
        var current = self.gifts
        guard let index = current.firstIndex(where: { $0.uid == uid }) else {
            return
        }
        let gift = current.remove(at: index)
        self.gifts = current
        self.appendTransfer(emoji: gift.emoji, title: gift.name, recipientName: recipientName, recipientId: recipientId, amount: gift.priceGram, isGram: false)
    }

    /// Debits visual gram and writes matching transfer and balance-history entries.
    @discardableResult
    public func recordGramTransfer(amount: Int64, recipientName: String, recipientId: Int64) -> Bool {
        let settings = TeleFlowSettings.shared
        guard amount > 0, !recipientName.isEmpty, settings.localGramValue >= amount else {
            return false
        }
        settings.addLocalGram(-amount)
        self.appendTransfer(emoji: "🔥", title: "Gram", recipientName: recipientName, recipientId: recipientId, amount: amount, isGram: true)
        self.appendTransaction(kind: .transfer, title: "Перевод gram", recipientName: recipientName, recipientId: recipientId, amount: -amount)
        return true
    }

    private func appendTransfer(emoji: String, title: String, recipientName: String, recipientId: Int64, amount: Int64, isGram: Bool) {
        let record = TeleFlowTransferRecord(
            uid: "tr." + String(UUID().uuidString.prefix(8)),
            emoji: emoji,
            title: title,
            recipientName: recipientName,
            recipientId: recipientId,
            amount: amount,
            isGram: isGram,
            date: Date().timeIntervalSince1970
        )
        var records = self.transfers
        records.append(record)
        self.transfers = records
    }

    private func appendTransaction(kind: TeleFlowGramTransactionKind, title: String, recipientName: String, recipientId: Int64, amount: Int64) {
        let record = TeleFlowGramTransaction(
            uid: "gr." + String(UUID().uuidString.prefix(8)),
            kind: kind,
            title: title,
            recipientName: recipientName,
            recipientId: recipientId,
            amount: amount,
            balanceAfter: TeleFlowSettings.shared.localGramValue,
            date: Date().timeIntervalSince1970
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

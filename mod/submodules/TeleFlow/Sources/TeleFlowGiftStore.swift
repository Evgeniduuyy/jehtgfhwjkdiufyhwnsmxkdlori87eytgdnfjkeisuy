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

    enum CodingKeys: String, CodingKey {
        case uid
        case name
        case emoji
        case priceGram
        case upgraded
        case crafted
        case inProfile
    }

    public init(uid: String, name: String, emoji: String, priceGram: Int64, upgraded: Bool = false, crafted: Bool = false, inProfile: Bool = false) {
        self.uid = uid
        self.name = name
        self.emoji = emoji
        self.priceGram = priceGram
        self.upgraded = upgraded
        self.crafted = crafted
        self.inProfile = inProfile
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

public final class TeleFlowGiftStore {
    public static let shared = TeleFlowGiftStore()

    private let key = "teleflow.showcaseGifts"
    private let transfersKey = "teleflow.transfers"

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

    public var transferCount: Int {
        return self.transfers.count
    }

    public var allTransfers: [TeleFlowTransferRecord] {
        return self.transfers
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
        current.append(TeleFlowShowcaseGift(uid: uid, name: catalogGift.name, emoji: catalogGift.emoji, priceGram: catalogGift.priceGram))
        self.gifts = current
        return true
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

    /// Removes the gift from the showcase and writes a visual transfer record.
    /// The record stays only on this device; no real message is ever sent.
    public func giftAway(uid: String, recipientName: String, recipientId: Int64) {
        var current = self.gifts
        guard let index = current.firstIndex(where: { $0.uid == uid }) else {
            return
        }
        let gift = current.remove(at: index)
        self.gifts = current
        let record = TeleFlowTransferRecord(
            uid: "tr." + String(UUID().uuidString.prefix(8)),
            emoji: gift.emoji,
            title: gift.name,
            recipientName: recipientName,
            recipientId: recipientId,
            amount: 0,
            isGram: false,
            date: Date().timeIntervalSince1970
        )
        var records = self.transfers
        records.append(record)
        self.transfers = records
    }

    /// Writes a visual gram transfer record. The caller is responsible for
    /// updating the local gram balance.
    public func recordGramTransfer(amount: Int64, recipientName: String, recipientId: Int64) {
        let record = TeleFlowTransferRecord(
            uid: "tr." + String(UUID().uuidString.prefix(8)),
            emoji: "🔥",
            title: "Gram",
            recipientName: recipientName,
            recipientId: recipientId,
            amount: amount,
            isGram: true,
            date: Date().timeIntervalSince1970
        )
        var records = self.transfers
        records.append(record)
        self.transfers = records
    }

    public func removeTransfer(uid: String) {
        var records = self.transfers
        records.removeAll { $0.uid == uid }
        self.transfers = records
    }

    public func removeAllTransfers() {
        self.transfers = []
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

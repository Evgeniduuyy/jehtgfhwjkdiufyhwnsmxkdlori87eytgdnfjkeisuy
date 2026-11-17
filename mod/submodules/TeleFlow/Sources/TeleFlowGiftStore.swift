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

    public init(uid: String, name: String, emoji: String, priceGram: Int64, upgraded: Bool = false, crafted: Bool = false) {
        self.uid = uid
        self.name = name
        self.emoji = emoji
        self.priceGram = priceGram
        self.upgraded = upgraded
        self.crafted = crafted
    }
}

public final class TeleFlowGiftStore {
    public static let shared = TeleFlowGiftStore()

    private let key = "teleflow.showcaseGifts"

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

    private init() {
    }

    public var count: Int {
        return self.gifts.count
    }

    public var all: [TeleFlowShowcaseGift] {
        return self.gifts
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

    public func remove(uid: String) {
        var current = self.gifts
        current.removeAll { $0.uid == uid }
        self.gifts = current
    }

    public func removeAll() {
        self.gifts = []
    }
}

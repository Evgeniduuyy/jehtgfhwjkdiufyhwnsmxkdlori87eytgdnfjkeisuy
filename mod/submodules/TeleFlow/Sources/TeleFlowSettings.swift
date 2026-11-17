import Foundation

/// All TeleFlow switches. Stored in UserDefaults so every module (core and UI) can read them
/// without depending on Telegram's own preference storage.
public final class TeleFlowSettings {
    public static let shared = TeleFlowSettings()

    private let defaults = UserDefaults.standard
    private let prefix = "teleflow."

    private init() {
        self.defaults.register(defaults: [
            self.prefix + "saveDeleted": true,
            self.prefix + "deletedIcon": "🗑",
            self.prefix + "deletedExcludeSecret": false,
            self.prefix + "deletedExcludePrivate": false,
            self.prefix + "deletedExcludeChannels": false,
            self.prefix + "deletedExcludeBots": false,
            self.prefix + "ghostHideOnline": false,
            self.prefix + "ghostHideTyping": false,
            self.prefix + "ghostHideReadReceipts": false,
            self.prefix + "hideSponsoredMessages": false,
            self.prefix + "localStarsEnabled": false,
            self.prefix + "localStarsValue": 0,
            self.prefix + "showPeerIdInProfile": true,
            self.prefix + "showKinopoiskBadge": true,
            self.prefix + "kinopoiskBadgeText": "Пользователь KinopoiskGram",
            self.prefix + "localGramEnabled": false,
            self.prefix + "localGramValue": 0
        ])
    }

    /// The current account's numeric id, published by the app on launch so the menu can show it.
    public var accountId: Int64 = 0

    private func bool(_ key: String) -> Bool {
        return self.defaults.bool(forKey: self.prefix + key)
    }

    private func setBool(_ key: String, _ value: Bool) {
        self.defaults.set(value, forKey: self.prefix + key)
    }

    // MARK: Deleted messages

    public var saveDeletedMessages: Bool {
        get { return self.bool("saveDeleted") }
        set { self.setBool("saveDeleted", newValue) }
    }

    public var deletedIcon: String {
        get { return self.defaults.string(forKey: self.prefix + "deletedIcon") ?? "🗑" }
        set { self.defaults.set(newValue, forKey: self.prefix + "deletedIcon") }
    }

    public var deletedExcludeSecret: Bool {
        get { return self.bool("deletedExcludeSecret") }
        set { self.setBool("deletedExcludeSecret", newValue) }
    }

    public var deletedExcludePrivate: Bool {
        get { return self.bool("deletedExcludePrivate") }
        set { self.setBool("deletedExcludePrivate", newValue) }
    }

    public var deletedExcludeChannels: Bool {
        get { return self.bool("deletedExcludeChannels") }
        set { self.setBool("deletedExcludeChannels", newValue) }
    }

    public var deletedExcludeBots: Bool {
        get { return self.bool("deletedExcludeBots") }
        set { self.setBool("deletedExcludeBots", newValue) }
    }

    // MARK: Ghost

    public var ghostHideOnline: Bool {
        get { return self.bool("ghostHideOnline") }
        set { self.setBool("ghostHideOnline", newValue) }
    }

    public var ghostHideTyping: Bool {
        get { return self.bool("ghostHideTyping") }
        set { self.setBool("ghostHideTyping", newValue) }
    }

    public var ghostHideReadReceipts: Bool {
        get { return self.bool("ghostHideReadReceipts") }
        set { self.setBool("ghostHideReadReceipts", newValue) }
    }

    // MARK: Other

    public var hideSponsoredMessages: Bool {
        get { return self.bool("hideSponsoredMessages") }
        set { self.setBool("hideSponsoredMessages", newValue) }
    }

    // MARK: Local stars (visual-only balance override)

    public var localStarsEnabled: Bool {
        get { return self.bool("localStarsEnabled") }
        set { self.setBool("localStarsEnabled", newValue) }
    }

    public var localStarsValue: Int64 {
        get { return Int64(self.defaults.integer(forKey: self.prefix + "localStarsValue")) }
        set { self.defaults.set(Int(newValue), forKey: self.prefix + "localStarsValue") }
    }

    /// If the visual override is on, returns the value to display instead of the real balance.
    public func overriddenStarsBalance(real: Int64) -> Int64 {
        return self.localStarsEnabled ? self.localStarsValue : real
    }

    // MARK: Profile header (visual, this device only)

    /// Appends " • ID: N" to the subtitle of every profile header.
    public var showPeerIdInProfile: Bool {
        get { return self.bool("showPeerIdInProfile") }
        set { self.setBool("showPeerIdInProfile", newValue) }
    }

    /// Shows the "Пользователь KinopoiskGram" badge in other people's profiles.
    public var showKinopoiskBadge: Bool {
        get { return self.bool("showKinopoiskBadge") }
        set { self.setBool("showKinopoiskBadge", newValue) }
    }

    /// The badge label, so it can be renamed in one place.
    public var kinopoiskBadgeText: String {
        get { return self.defaults.string(forKey: self.prefix + "kinopoiskBadgeText") ?? "Пользователь KinopoiskGram" }
        set { self.defaults.set(newValue, forKey: self.prefix + "kinopoiskBadgeText") }
    }

    // MARK: Local gram (visual-only balance, like local stars)

    public var localGramEnabled: Bool {
        get { return self.bool("localGramEnabled") }
        set { self.setBool("localGramEnabled", newValue) }
    }

    public var localGramValue: Int64 {
        get { return Int64(self.defaults.integer(forKey: self.prefix + "localGramValue")) }
        set { self.defaults.set(Int(newValue), forKey: self.prefix + "localGramValue") }
    }

    /// Changes the visual gram balance by a signed amount. Returns the new value.
    @discardableResult
    public func addLocalGram(_ amount: Int64) -> Int64 {
        let value = max(0, self.localGramValue + amount)
        self.localGramValue = value
        return value
    }
}

/// Kinds of chats, used by the deleted-message exclusions.
public enum TeleFlowChatKind {
    case privateChat
    case bot
    case channel
    case group
    case secret
}

public extension TeleFlowSettings {
    func shouldKeepDeletedMessages(in kind: TeleFlowChatKind) -> Bool {
        if !self.saveDeletedMessages {
            return false
        }
        switch kind {
        case .privateChat:
            return !self.deletedExcludePrivate
        case .bot:
            return !self.deletedExcludeBots
        case .channel:
            return !self.deletedExcludeChannels
        case .secret:
            return !self.deletedExcludeSecret
        case .group:
            return true
        }
    }
}

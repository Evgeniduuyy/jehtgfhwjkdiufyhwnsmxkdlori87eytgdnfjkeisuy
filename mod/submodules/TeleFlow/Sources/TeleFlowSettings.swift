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
            self.prefix + "ghostHideTyping": false
        ])
    }

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

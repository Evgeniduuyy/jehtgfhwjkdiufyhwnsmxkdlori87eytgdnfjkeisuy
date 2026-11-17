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
            self.prefix + "ghostAlwaysOnline": false,
            self.prefix + "ghostHideTyping": false,
            self.prefix + "ghostHideRecording": false,
            self.prefix + "ghostHideUploading": false,
            self.prefix + "ghostHideReadReceipts": false,
            self.prefix + "hideSponsoredMessages": false,
            self.prefix + "hideSearchAds": false,
            self.prefix + "hideMyStars": false,
            self.prefix + "localStarsEnabled": false,
            self.prefix + "localStarsValue": 0,
            self.prefix + "showPeerIdInProfile": true,
            self.prefix + "showKinopoiskBadge": true,
            self.prefix + "kinopoiskBadgeText": "Пользователь KinopoiskGram",
            self.prefix + "localGramEnabled": false,
            self.prefix + "localGramValue": 0,
            self.prefix + "zalgoFilter": false,
            self.prefix + "fullTimeServiceMessages": false,
            self.prefix + "hideGiftsTab": false,
            self.prefix + "personalProfileBackground": false,
            self.prefix + "showTypingCharacterCounter": false,
            self.prefix + "showMessageCharacterCount": false,
            self.prefix + "unlimitedRecentStickers": false,
            self.prefix + "unlimitedFavoriteStickers": false,
            self.prefix + "uploadSmallFileStreams": 0,
            self.prefix + "uploadBigFileStreams": 0,
            self.prefix + "downloadSmallFileStreams": 0,
            self.prefix + "downloadBigFileStreams": 0,
            self.prefix + "downloadStoryStreams": 0,
            self.prefix + "stickerSizePercent": 100
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

    public var ghostAlwaysOnline: Bool {
        get { return self.bool("ghostAlwaysOnline") }
        set { self.setBool("ghostAlwaysOnline", newValue) }
    }

    public var ghostHideTyping: Bool {
        get { return self.bool("ghostHideTyping") }
        set { self.setBool("ghostHideTyping", newValue) }
    }

    public var ghostHideRecording: Bool {
        get { return self.bool("ghostHideRecording") }
        set { self.setBool("ghostHideRecording", newValue) }
    }

    public var ghostHideUploading: Bool {
        get { return self.bool("ghostHideUploading") }
        set { self.setBool("ghostHideUploading", newValue) }
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

    /// Hides promoted peers in Search when results are next assembled.
    public var hideSearchAds: Bool {
        get { return self.bool("hideSearchAds") }
        set { self.setBool("hideSearchAds", newValue) }
    }

    /// Hides only the "My Stars" settings row; direct Stars screens still work.
    public var hideMyStars: Bool {
        get { return self.bool("hideMyStars") }
        set { self.setBool("hideMyStars", newValue) }
    }

    // MARK: Local stars (visual-only balance override)

    public var localStarsEnabled: Bool {
        get { return self.bool("localStarsEnabled") }
        set { self.setBool("localStarsEnabled", newValue) }
    }

    public var localStarsValue: Int64 {
        get { return max(0, Int64(self.defaults.integer(forKey: self.prefix + "localStarsValue"))) }
        set { self.defaults.set(Int(max(0, newValue)), forKey: self.prefix + "localStarsValue") }
    }

    /// Changes the local visual star balance used by the gift market.
    @discardableResult
    public func addLocalStars(_ amount: Int64) -> Int64 {
        let (sum, overflow) = self.localStarsValue.addingReportingOverflow(amount)
        let value = overflow ? (amount >= 0 ? Int64.max : 0) : max(0, sum)
        self.localStarsValue = value
        return value
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

    /// Shows the badge on your own profile; Telegram cannot verify another user's client.
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
        get { return max(0, Int64(self.defaults.integer(forKey: self.prefix + "localGramValue"))) }
        set { self.defaults.set(Int(max(0, newValue)), forKey: self.prefix + "localGramValue") }
    }

    /// Changes the visual gram balance by a signed amount. Returns the new value.
    @discardableResult
    public func addLocalGram(_ amount: Int64) -> Int64 {
        let (sum, overflow) = self.localGramValue.addingReportingOverflow(amount)
        let value = overflow ? (amount >= 0 ? Int64.max : 0) : max(0, sum)
        self.localGramValue = value
        return value
    }

    // MARK: Chat & interface (local, this device only)

    /// Strips zalgo combining marks from message text before rendering.
    public var zalgoFilter: Bool {
        get { return self.bool("zalgoFilter") }
        set { self.setBool("zalgoFilter", newValue) }
    }

    /// Appends the full date and time to service messages (joins, calls, etc.).
    public var fullTimeServiceMessages: Bool {
        get { return self.bool("fullTimeServiceMessages") }
        set { self.setBool("fullTimeServiceMessages", newValue) }
    }

    /// Hides the Gifts tab in all profiles.
    public var hideGiftsTab: Bool {
        get { return self.bool("hideGiftsTab") }
        set { self.setBool("hideGiftsTab", newValue) }
    }

    /// Uses your name color as a local profile background when no profile color is set.
    public var personalProfileBackground: Bool {
        get { return self.bool("personalProfileBackground") }
        set { self.setBool("personalProfileBackground", newValue) }
    }

    public var showTypingCharacterCounter: Bool {
        get { return self.bool("showTypingCharacterCounter") }
        set { self.setBool("showTypingCharacterCounter", newValue) }
    }

    public var showMessageCharacterCount: Bool {
        get { return self.bool("showMessageCharacterCount") }
        set { self.setBool("showMessageCharacterCount", newValue) }
    }

    public var unlimitedRecentStickers: Bool {
        get { return self.bool("unlimitedRecentStickers") }
        set { self.setBool("unlimitedRecentStickers", newValue) }
    }

    public var unlimitedFavoriteStickers: Bool {
        get { return self.bool("unlimitedFavoriteStickers") }
        set { self.setBool("unlimitedFavoriteStickers", newValue) }
    }

    private func streamCount(_ key: String) -> Int {
        return max(0, min(64, self.defaults.integer(forKey: self.prefix + key)))
    }

    private func setStreamCount(_ key: String, _ value: Int) {
        self.defaults.set(max(0, min(64, value)), forKey: self.prefix + key)
    }

    /// Zero keeps Telegram's stock concurrency. Changes affect new transfers.
    public var uploadSmallFileStreams: Int {
        get { return self.streamCount("uploadSmallFileStreams") }
        set { self.setStreamCount("uploadSmallFileStreams", newValue) }
    }

    public var uploadBigFileStreams: Int {
        get { return self.streamCount("uploadBigFileStreams") }
        set { self.setStreamCount("uploadBigFileStreams", newValue) }
    }

    public var downloadSmallFileStreams: Int {
        get { return self.streamCount("downloadSmallFileStreams") }
        set { self.setStreamCount("downloadSmallFileStreams", newValue) }
    }

    public var downloadBigFileStreams: Int {
        get { return self.streamCount("downloadBigFileStreams") }
        set { self.setStreamCount("downloadBigFileStreams", newValue) }
    }

    public var downloadStoryStreams: Int {
        get { return self.streamCount("downloadStoryStreams") }
        set { self.setStreamCount("downloadStoryStreams", newValue) }
    }

    /// Local sticker display size, percent of the stock size (50...150).
    public var stickerSizePercent: Int {
        get {
            let value = self.defaults.integer(forKey: self.prefix + "stickerSizePercent")
            return max(50, min(150, value))
        }
        set {
            self.defaults.set(max(50, min(150, newValue)), forKey: self.prefix + "stickerSizePercent")
        }
    }

    // MARK: Export / import

    /// A JSON-serializable snapshot of every stored TeleFlow setting.
    public func makeExport() -> [String: Any] {
        let representation = self.defaults.dictionaryRepresentation()
        var result: [String: Any] = [:]
        for (key, value) in representation where key.hasPrefix(self.prefix) {
            result[key] = value
        }
        return result
    }

    /// Applies an imported snapshot, ignoring keys that do not belong to TeleFlow.
    public func applyImport(_ values: [String: Any]) {
        for (key, value) in values where key.hasPrefix(self.prefix) {
            if let boolValue = value as? Bool {
                self.defaults.set(boolValue, forKey: key)
            } else if let intValue = value as? Int {
                self.defaults.set(intValue, forKey: key)
            } else if let stringValue = value as? String {
                self.defaults.set(stringValue, forKey: key)
            }
        }
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

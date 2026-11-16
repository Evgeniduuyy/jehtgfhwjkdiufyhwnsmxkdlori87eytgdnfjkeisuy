import Foundation

/// Remembers which messages were deleted by the other side but kept on this device.
/// A message is identified by "peerId:namespace:id".
public final class TeleFlowDeletedStore {
    public static let shared = TeleFlowDeletedStore()

    private let key = "teleflow.deletedMessageKeys"
    private let maxCount = 20000
    private let lock = NSLock()
    private var keys: [String]
    private var keySet: Set<String>

    private init() {
        let stored = UserDefaults.standard.stringArray(forKey: self.key) ?? []
        self.keys = stored
        self.keySet = Set(stored)
    }

    public static func makeKey(peerId: Int64, namespace: Int32, id: Int32) -> String {
        return "\(peerId):\(namespace):\(id)"
    }

    public func markDeleted(peerId: Int64, namespace: Int32, id: Int32) {
        let key = TeleFlowDeletedStore.makeKey(peerId: peerId, namespace: namespace, id: id)
        self.lock.lock()
        if !self.keySet.contains(key) {
            self.keySet.insert(key)
            self.keys.append(key)
            if self.keys.count > self.maxCount {
                let overflow = self.keys.count - self.maxCount
                for oldKey in self.keys.prefix(overflow) {
                    self.keySet.remove(oldKey)
                }
                self.keys.removeFirst(overflow)
            }
            UserDefaults.standard.set(self.keys, forKey: self.key)
        }
        self.lock.unlock()
    }

    public func isDeleted(peerId: Int64, namespace: Int32, id: Int32) -> Bool {
        let key = TeleFlowDeletedStore.makeKey(peerId: peerId, namespace: namespace, id: id)
        self.lock.lock()
        let result = self.keySet.contains(key)
        self.lock.unlock()
        return result
    }

    public var count: Int {
        self.lock.lock()
        let result = self.keys.count
        self.lock.unlock()
        return result
    }

    public func removeAll() {
        self.lock.lock()
        self.keys.removeAll()
        self.keySet.removeAll()
        UserDefaults.standard.removeObject(forKey: self.key)
        self.lock.unlock()
    }
}

//
//  Cache.swift
//  Tinodios
//
//  Copyright © 2019 Tinode. All rights reserved.
//

import UIKit
import TinodeSDK
import TinodiosDB
import Firebase

class Cache {
    private static let `default` = Cache()

    private var tinodeInstance: Tinode? = nil
    private var corefInstance: Coref? = nil
    private var detectorInstance: MisusedPronounDectector? = nil
    private var timer = RepeatingTimer(timeInterval: 60 * 60 * 4) // Once every 4 hours.
    private var largeFileHelper: LargeFileHelper? = nil
    private var queue = DispatchQueue(label: "co.tinode.cache")
    internal static let log = TinodeSDK.Log(subsystem: "co.tinode.tinodios")

    public static var tinode: Tinode {
        return Cache.default.getTinode()
    }
    
    // MARK - PT APP
    public static var coref: Coref {
        return Cache.default.getCoref()
    }
    public static var misusedPronounDetector: MisusedPronounDectector {
        return Cache.default.getDetector()
    }
    public static func getLargeFileHelper(withIdentifier identifier: String? = nil) -> LargeFileHelper {
        return Cache.default.getLargeFileHelper(withIdentifier: identifier)
    }
    public static func invalidate() {
        if let tinode = Cache.default.tinodeInstance {
            Cache.default.timer.suspend()
            tinode.logout()
            Messaging.messaging().deleteToken { error in
                Cache.log.debug("Failed to delete FCM token: %@", error.debugDescription)
            }
            Cache.default.tinodeInstance = nil
        }
    }
    public static func isContactSynchronizerActive() -> Bool {
        return Cache.default.timer.state == .resumed
    }
    public static func synchronizeContactsPeriodically() {
        Cache.default.timer.suspend()
        // Try to syncmehronize contacts immediately
        ContactsSynchronizer.default.run()
        // And repeat once every 4 hours.
        Cache.default.timer.eventHandler = { ContactsSynchronizer.default.run() }
        Cache.default.timer.resume()
    }
    private func getTinode() -> Tinode {
        // TODO: fix tsan false positive.
        // TSAN fires because one thread may read |tinode| variable
        // while another thread may be writing it below in the critical section.
        if tinodeInstance == nil {
            queue.sync {
                if tinodeInstance == nil {
                    tinodeInstance = SharedUtils.createTinode()
                    // Tell contacts synchronizer to attempt to synchronize contacts.
                    ContactsSynchronizer.default.appBecameActive()
                }
            }
        }
        return tinodeInstance!
    }
    // MARK - PT APP
    private func getCoref() -> Coref {
        if corefInstance == nil {
            corefInstance = Coref()
        }
        return corefInstance!
    }
    private func getDetector() -> MisusedPronounDectector {
        if detectorInstance == nil {
            detectorInstance = MisusedPronounDectector()
        }
        return detectorInstance!
    }
    
    private func getLargeFileHelper(withIdentifier identifier: String?) -> LargeFileHelper {
        if largeFileHelper == nil {
            let id = identifier ?? "tinode-\(Date().millisecondsSince1970)"
            let config = URLSessionConfiguration.background(withIdentifier: id)
            largeFileHelper = LargeFileHelper(with: Cache.tinode, config: config)
        }
        return largeFileHelper!
    }

    public static func totalUnreadCount() -> Int {
        guard let topics = tinode.getTopics() else {
            return 0
        }
        return topics.reduce(into: 0, { result, topic in
            result += topic.isReader && !topic.isMuted ? topic.unread : 0
        })
    }
}

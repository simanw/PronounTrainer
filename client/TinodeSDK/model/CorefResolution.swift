//
//  File.swift
//  TinodeSDK
//
//  Created by Wang Siman on 2/22/21.
//  Copyright © 2021 Tinode. All rights reserved.
//

import Foundation

class Mention: Codable {
    var start: Int
    var end: Int
    var text: String
    var resolved: String
}

typealias Cluster = [String]

public class CorefResolution: Codable {
    var mentions: [Mention]
    var clusters: [Cluster]
    var resolvedString: String
}

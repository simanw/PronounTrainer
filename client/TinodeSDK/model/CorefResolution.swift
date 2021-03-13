//
//  File.swift
//  TinodeSDK
//
//  Created by Wang Siman on 2/22/21.
//  Copyright © 2021 Tinode. All rights reserved.
//

import Foundation

public struct Mention: Codable {
    public var start: Int
    public var end: Int
    public var text: String
    public var resolved: String
}

public typealias Cluster = [String]

public struct CorefResolution: Codable {
    public var mentions: [Mention]
    public var clusters: [Cluster]
    public var resolved: String
}

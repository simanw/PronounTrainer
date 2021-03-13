//
//  MisusedPronounDetector.swift
//  Tinodios
//
//  Created by Wang Siman on 2/22/21.
//  Copyright © 2021 Tinode. All rights reserved.
//

import Foundation
import TinodeSDK

public struct MisusedPronounPair {
    public var name: String
    public var preferredPronouns: Set<Pronoun>
    public var wrongPronoun: String
}

public class MisusedPronounDectector {
    
    private var contactManager = ContactsManager()
    private var contacts: [ContactHolder]?
    private var contactsPronounsMap: [String:Set<Pronoun>] = [:]
    private var nameContactsMap: [String: [ContactHolder]] = [:]
    
    init() {
        self.contacts = contactManager.fetchContacts()
        createContactsMap()
    }
    
    private func createContactsMap() {
        guard let contacts = self.contacts else {
            return
        }
        for contact in contacts {
//            if let uniqueId = contact.uniqueId, let p = contact.pronouns{
//                self.contactsPronounsMap[uniqueId] = p
//            }
            if let name = contact.displayName, let p = contact.pronouns {
                let firstName = name.split(separator: " ")[0]
                self.contactsPronounsMap[String(firstName)] = p
            }
        }
        
    }
    
    private func createNameContactsMap() {
        guard let contacts = self.contacts else {
            return
        }
        for contact in contacts {
            if let name = contact.displayName {
                let firstName = name.split(separator: " ")[0]
                var bucket = self.nameContactsMap[String(firstName), default: []]
                bucket.append(contact)
            }
        }
    }
    
    
    public func updateContactsMap() {
        self.contacts = contactManager.fetchContacts()
        createContactsMap()
    }
    
//    public func detect_(_ resolved: CorefResolution, after: Int) -> [MisusedPronounPair] {
//        var misusedPairs: [MisusedPronounPair] = []
//        var seenNames: Set<String> = []
//        for mention in resolved.mentions {
//            if mention.start >= after {
//                let name = mention.resolved
//                let resolvedPronoun = mention.text
//
//
//            }
//        }
//    }
    
    public func detect(_ resolved: CorefResolution, after: Int) -> [MisusedPronounPair] {
        var misusedPairs: [MisusedPronounPair] = []
        var seenNames: Set<String> = []
        for mention in resolved.mentions {
            if mention.start >= after {
                let name = mention.resolved
                let resolvedPronoun = mention.text
                
                if let preferredPronouns = self.contactsPronounsMap[name] {
                    if !seenNames.contains(name) && !preferredPronouns.contains(resolvedPronoun) {
                        misusedPairs.append(MisusedPronounPair(
                            name: name, preferredPronouns: preferredPronouns, wrongPronoun: resolvedPronoun
                        ))
                        seenNames.insert(name)
                    }
                }

            }
        }
        return misusedPairs
    }
}

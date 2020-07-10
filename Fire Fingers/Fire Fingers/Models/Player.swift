//
//  Project: Fire-Fingers
//  Filename: Player.swift
//  EID: gh22593 + gwe272
//  Course: CS371L
//
//  Created by Grant He & Garrett Egan on 7/4/20.
//  Copyright © 2020 G + G. All rights reserved.
//

import FirebaseFirestore

class Player {
    
    // unique identifier
    let uuid: String
    
    // public name of the player
    let displayName: String
    
    // index of player's icon
    let icon: Int
    
    // index of word player is on in prompt
    var currentWord: Int
    
    // player is ready
    var ready: Bool
    
    // player is ready
    var completionTime: Double?
    
    init(uuid: String, displayName: String, icon: Int) {
        self.uuid = uuid
        self.displayName = displayName
        self.currentWord = 0
        self.icon = icon
        self.ready = false
        self.completionTime = nil
    }
    
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let uuid = (data["uuid"] as? String) else {
            NSLog("Player failed to convert uuid '\(String(describing: data["uuid"]))'")
            return nil
        }
        
        guard let displayName = data["displayName"] as? String else {
            NSLog("Player failed to convert displayName '\(String(describing: data["displayName"]))'")
            return nil
        }
        
        guard let currentWord = data["currentWord"] as? Int else {
            NSLog("Player failed to convert currentWord '\(String(describing: data["currentWord"]))'")
            return nil
        }
        
        guard let icon = data["icon"] as? Int else {
            NSLog("Player failed to convert icon '\(String(describing: data["icon"]))'")
            return nil
        }
        
        guard let ready = data["ready"] as? Bool else {
            NSLog("Player failed to convert ready '\(String(describing: data["ready"]))'")
            return nil
        }
        
        self.uuid = uuid
        self.displayName = displayName
        self.currentWord = currentWord
        self.icon = icon
        self.ready = ready
        self.completionTime = data["completionTime"] as? Double
    }
}

extension Player: DatabaseRepresentation {
    
    var representation: [String: Any] {
        return [
            "uuid": uuid,
            "displayName": displayName,
            "currentWord": currentWord,
            "icon": icon,
            "ready": ready,
            "completionTime": completionTime as Any
        ]
    }
}

extension Player: Equatable {
    
    static func == (lhs: Player, rhs: Player) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}

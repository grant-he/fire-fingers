//
//  Project: Fire-Fingers
//  Filename: GameLobby.swift
//  EID: gh22593 + gwe272
//  Course: CS371L
//
//  Created by Grant He & Garrett Egan on 7/4/20.
//  Copyright © 2020 G + G. All rights reserved.
//

import FirebaseFirestore

class GameLobby {
    var id: String?
    var chatLobbyID: String
    let gameSettings: GameSettings
    
    init(chatLobbyID: String, gameSettings: GameSettings) {
        self.chatLobbyID = chatLobbyID
        self.gameSettings = gameSettings
    }
    
    init?(data: [String : Any]) {
        
        guard let id = (data["id"] as? String) else {
            print("GameLobby failed to convert id '\(String(describing: data["id"]))'")
            return nil
        }
        
        guard let chatLobbyID = data["chatLobbyID"] as? String else {
            print("GameLobby failed to convert chatLobbyID '\(String(describing: data["chatLobbyID"]))'")
            return nil
        }
        
        guard let gameSettings = GameSettings(data: data["gameSettings"] as! [String : Any]) else {
            print("GameLobby failed to convert gameSettings '\(String(describing: data["gameSettings"]))'")
            return nil
        }
        
        self.id = id
        self.chatLobbyID = chatLobbyID
        self.gameSettings = gameSettings
    }
}

extension GameLobby: DatabaseRepresentation {
    
    var representation: [String : Any] {
    
        var rep: [String : Any] = [
            "chatLobbyID" : chatLobbyID,
            "gameSettings" : gameSettings.representation
        ]
    
        if let id = id {
            rep["id"] = id
        }
    
        return rep
    }
}

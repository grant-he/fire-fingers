//
//  GameResult.swift
//  Fire Fingers
//
//  Created by Garrett Egan on 7/7/20.
//  Copyright © 2020 G + G. All rights reserved.
//
import FirebaseFirestore
class GameResult {
    let user: String
    let wordCount: Int
    let time: Double
    
    init(user: String, wordCount: Int, time: Double) {
        self.user = user
        self.wordCount = wordCount
        self.time = time
    }
    
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let user = data["user"] as? String else {
            print("GameResult failed to convert user '\(String(describing: data["user"]))'")
            return nil
        }
        
        guard let wordCount = data["wordCount"] as? Int else {
            print("GameResult failed to convert wordCount '\(String(describing: data["wordCount"]))'")
            return nil
        }
        
        guard let time = data["time"] as? Double else {
            print("GameResult failed to convert time '\(String(describing: data["time"]))'")
            return nil
        }
        
        self.user = user
        self.wordCount = wordCount
        self.time = time
    }
}

    extension GameResult: DatabaseRepresentation {
        
        var representation: [String : Any] {
        
            return [
                "user" : user,
                "wordCount" : wordCount,
                "time" : time
            ]
        }
    }

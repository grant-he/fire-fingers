//
//  Project: Fire-Fingers
//  Filename: Prompt.swift
//  EID: gh22593 + gwe272
//  Course: CS371L
//
//  Created by Grant He & Garrett Egan on 7/7/20.
//  Copyright © 2020 G + G. All rights reserved.
//

import FirebaseFirestore

class Prompt {
    let hasEmojis: Bool
    let numWords: Int
    let prompt: String
    
    init(hasEmojis: Bool, numWords: Int, prompt: String) {
        self.hasEmojis = hasEmojis
        self.numWords = numWords
        self.prompt = prompt
    }
    
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let hasEmojis = data["hasEmojis"] as? Bool else {
            print("Prompt failed to convert hasEmojis '\(String(describing: data["hasEmojis"]))'")
            return nil
        }
        
        guard let numWords = data["numWords"] as? Int else {
            print("Prompt failed to convert numWords '\(String(describing: data["numWords"]))'")
            return nil
        }
        
        guard let prompt = data["prompt"] as? String else {
            print("Prompt failed to convert prompt '\(String(describing: data["prompt"]))'")
            return nil
        }
        
        self.hasEmojis = hasEmojis
        self.numWords = numWords
        self.prompt = prompt
    }
    
    init?(data: [String : Any]) {
        
        guard let hasEmojis = data["hasEmojis"] as? Bool else {
            print("Prompt failed to convert hasEmojis '\(String(describing: data["hasEmojis"]))'")
            return nil
        }
        
        guard let numWords = data["numWords"] as? Int else {
            print("Prompt failed to convert numWords '\(String(describing: data["numWords"]))'")
            return nil
        }
        
        guard let prompt = data["prompt"] as? String else {
            print("Prompt failed to convert prompt '\(String(describing: data["prompt"]))'")
            return nil
        }
        
        self.hasEmojis = hasEmojis
        self.numWords = numWords
        self.prompt = prompt
    }
}

extension Prompt : DatabaseRepresentation {

    var representation: [String : Any] {
        
        return [
            "hasEmojis" : hasEmojis,
            "numWords" : numWords,
            "prompt" : prompt
        ]
    }
}

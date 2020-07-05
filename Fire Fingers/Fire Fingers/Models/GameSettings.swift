//
//  GameSettings.swift
//  Fire Fingers
//
//  Created by Garrett Egan on 7/4/20.
//  Copyright © 2020 G + G. All rights reserved.
//

import FirebaseFirestore

class GameSettings {
    let instantDeathModeEnabled: Bool
    let earthQuakeModeEnabled: Bool
    let emojisAllowed: Bool
    let playersCount: Int8
    
    init(instantDeathModeEnabled: Bool, earthQuakeModeEnabled: Bool, emojisAllowed: Bool, playersCount: Int8) {
        self.instantDeathModeEnabled = instantDeathModeEnabled
        self.earthQuakeModeEnabled = earthQuakeModeEnabled
        self.emojisAllowed = emojisAllowed
        self.playersCount = playersCount
    }
    
    init?(data: [String : Any]) {
      guard let instantDeathModeEnabled = (data["instantDeathModeEnabled"] as? Bool) else {
          print("GameSettings failed to convert instantDeathModeEnabled '\(String(describing: data["instantDeathModeEnabled"]))'")
        return nil
      }
      guard let earthQuakeModeEnabled = data["earthQuakeModeEnabled"] as? Bool else {
          print("GameSettings failed to convert earthQuakeModeEnabled '\(String(describing: data["earthQuakeModeEnabled"]))'")
        return nil
      }
      guard let emojisAllowed = data["emojisAllowed"] as? Bool else {
          print("GameSettings failed to convert emojisAllowed '\(String(describing: data["emojisAllowed"]))'")
        return nil
      }
      guard let playersCount = data["playersCount"] as? Int8 else {
          print("GameSettings failed to convert playersCount '\(String(describing: data["playersCount"]))'")
        return nil
      }
      
      self.instantDeathModeEnabled = instantDeathModeEnabled
      self.earthQuakeModeEnabled = earthQuakeModeEnabled
      self.emojisAllowed = emojisAllowed
      self.playersCount = playersCount
    }
}

extension GameSettings: DatabaseRepresentation {
  
  var representation: [String : Any] {
    
    return ["instantDeathModeEnabled" : instantDeathModeEnabled,
            "earthQuakeModeEnabled" : earthQuakeModeEnabled,
            "emojisAllowed" : emojisAllowed,
            "playersCount" : playersCount]
    }
}

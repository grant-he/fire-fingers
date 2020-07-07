//
//  leaderboardEntry.swift
//  Fire Fingers
//
//  Created by Garrett Egan on 7/7/20.
//  Copyright © 2020 G + G. All rights reserved.
//

class LeaderboardEntry {
    let user: String
    let bestWPM: Double
    let avgWPM: Double
    
    init(user: String, bestWPM: Double, avgWPM: Double) {
        self.user = user
        self.bestWPM = bestWPM
        self.avgWPM = avgWPM
    }
}

extension LeaderboardEntry: Comparable {
    static func < (lhs: LeaderboardEntry, rhs: LeaderboardEntry) -> Bool {
        return lhs.avgWPM > rhs.avgWPM
    }
    
    static func == (lhs: LeaderboardEntry, rhs: LeaderboardEntry) -> Bool {
        return lhs.user == rhs.user
    }
    
    
}

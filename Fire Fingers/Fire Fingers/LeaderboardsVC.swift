//
//  Project: Fire-Fingers
//  Filename: LeaderboardsVC.swift
//  EID: gh22593 + gwe272
//  Course: CS371L
//
//  Created by Grant He & Garrett Egan on 6/30/20.
//  Copyright © 2020 G + G. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class LeaderboardsVC: UIViewController {
    
    // database
    private let db = Firestore.firestore()
    
    // the stats of all players
    var playerStats: [String: (Int64, Double, Double)] = [:]
    
    // the ordered leaderboard entries of all players
    var orderedPlayerRankings: [LeaderboardEntry] = []
    
    // the leaderboard entry for the signed in player
    var playerEntry: LeaderboardEntry?
    
    @IBOutlet weak var rankLabel: UILabel!
    @IBOutlet weak var bestWPMLabel: UILabel!
    @IBOutlet weak var avgWPMLabel: UILabel!
    @IBOutlet weak var leaderboardsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        insertData()

        leaderboardsTableView.delegate = self
        leaderboardsTableView.dataSource = self
        
        // load and process all the stats data
        let gamesReference = self.db.collection("GameResults")
        gamesReference.getDocuments() { (querySnapshot, err) in
            if let err = err {
                NSLog("Error getting documents: \(err)")
                return
            } else {
                self.processGamesData(documents: querySnapshot!.documents);
            }
        }
    }
    
    // takes all the game records in the database and creates a leaderboard
    func processGamesData(documents: [QueryDocumentSnapshot]) {
        for document in documents {
            guard let result = GameResult(document: document) else {
                NSLog("Failed to create GameResult for leaderboards, skipping")
                continue
            }
            
            // insert the respective user if they do not exist
            if !playerStats.keys.contains(result.user) {
                playerStats[result.user] = (0,0.0,0.0)
            }
            
            // update their total words and total time typing
            playerStats[result.user]!.0 += Int64(result.wordCount)
            playerStats[result.user]!.1 += result.time
            
            // override this player's best wpm if this game run was faster
            let resultWPM = Double(result.wordCount) / (result.time / 60.0)
            if resultWPM > playerStats[result.user]!.2 {
                playerStats[result.user]!.2 = resultWPM
            }
        }
        
        // turn the total words and times into an average
        for player in playerStats.keys {
            let playerTotalWords = playerStats[player]!.0
            let playerTotalMinutes = playerStats[player]!.1 / 60
            let playerAvgWPM: Double = Double(playerTotalWords) / playerTotalMinutes
            let playerBestWPM = (playerStats[player]!.2)
            orderedPlayerRankings.append(LeaderboardEntry(user: player, bestWPM: playerBestWPM, avgWPM: playerAvgWPM))
            
            // if this player is the current logged in player, store their info
            if playerEntry == nil, player == Auth.auth().currentUser?.email {
                playerEntry = orderedPlayerRankings[orderedPlayerRankings.count - 1]
            }
        }
        orderedPlayerRankings.sort()
        updateUI()
    }
    
    func updateUI() {
        
        // put the stats of the current logged in user at the top
        if !Auth.auth().currentUser!.isAnonymous {
            if playerEntry == nil {
                orderedPlayerRankings.append(LeaderboardEntry(user: Auth.auth().currentUser!.email!, bestWPM: 0, avgWPM: 0))
                playerEntry = orderedPlayerRankings[orderedPlayerRankings.count - 1]
            }
            
            let playerRank = orderedPlayerRankings.firstIndex(of: playerEntry!)! + 1
            rankLabel.text = String(playerRank)
            bestWPMLabel.text = String(format: "%.2f", playerEntry!.bestWPM)
            avgWPMLabel.text = String(format: "%.2f", playerEntry!.avgWPM)
        }
        
        // reload the data of the full leaderboard
        leaderboardsTableView.reloadData()
    }
}

extension LeaderboardsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orderedPlayerRankings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LeaderboardCell", for: indexPath) as! LeaderboardViewCell
        let row = indexPath.row
        let leaderboardEntry = orderedPlayerRankings[row]
        
        cell.rankLabel.text = String(row + 1)
        cell.nameLabel.text = leaderboardEntry.user
        cell.bestWPMLabel.text = String(format: "%.2f", leaderboardEntry.bestWPM)
        cell.avgWPMLabel.text = String(format: "%.2f", leaderboardEntry.avgWPM)
        
        return cell
    }
}

// inserting stuff
extension LeaderboardsVC {
    func insertData() {
        uploadGameResult(results: GameResult(user: "garrettegan@utexas.edu", wordCount: 30, time: 5.5))
        uploadGameResult(results: GameResult(user: "garrettegan@utexas.edu", wordCount: 30, time: 4.5))
        uploadGameResult(results: GameResult(user: "garrettegan@utexas.edu", wordCount: 30, time: 3.5))
        
        uploadGameResult(results: GameResult(user: "Grant", wordCount: 300, time: 3))
        
    }
    
    func uploadGameResult(results: GameResult) {
        let gamesReference = db.collection("GameResults")
        gamesReference.addDocument(data: results.representation) { error in
            if let e = error {
                NSLog("Error saving player: \(e.localizedDescription)")
            }
        }
    }
}

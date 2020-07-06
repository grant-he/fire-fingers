//
//  Project: Fire-Fingers
//  Filename: MainVC.swift
//  EID: gh22593 + gwe272
//  Course: CS371L
//
//  Created by Grant He & Garrett Egan on 6/27/20.
//  Copyright © 2020 G + G. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

// Current user settings
var loggedInUserSettings: Dictionary<String, Any> = [:]

// Property names
let userSettingsEntityName = "UserSettings"
let userSettingsUsernameAttribute = "username"
let userSettingsDarkModeAttribute = "darkModeEnabled"
let userSettingsVolumeAttribute = "volume"
let userSettingsIconAttribute = "icon"

class MainVC: UIViewController {
    let joinLobbySegue = "JoinLobbySegue"
    
    // database
    private let db = Firestore.firestore()
    
    var gameLobby: GameLobby!
    var chatLobby: ChatLobby!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func joinLobbyButtonPressed(_ sender: Any) {
        showJoinLobbyAlert(message: nil)
        
    }
    
    func showJoinLobbyAlert(message: String?) {
        let alert = UIAlertController(title: "Enter Lobby Code", message: message, preferredStyle: .alert)

        alert.addTextField { (textField) in
            textField.text = ""
        }

        alert.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: nil))
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert!.textFields![0] // Force unwrapping because we know it exists.
            self.attemptLobbyJoin(lobbyCode: textField.text)
        }))

        self.present(alert, animated: message == nil, completion: nil)
    }
    
    func attemptLobbyJoin(lobbyCode: String?) {
        guard lobbyCode != nil, !lobbyCode!.isEmpty else {
            showJoinLobbyAlert(message: "Please enter a lobby code")
            return
        }
        
        let gameLobbyRef = db.collection("gameLobbies").document(lobbyCode!)
        gameLobbyRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let dataDescription = document.data()!
                guard let gameLobbyObj = GameLobby(data: dataDescription) else {
                    print("Failed to create GameLobby for lobby code \(String(describing: lobbyCode))")
                    return
                }
                let playersReference = self.db.collection(["gameLobbies", lobbyCode!, "players"].joined(separator: "/"))
                playersReference.getDocuments() { (querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                        return
                    } else {
                        let playersInLobby = querySnapshot!.count
                        guard playersInLobby < gameLobbyObj.gameSettings.playersCount else {
                            self.showJoinLobbyAlert(message: "Lobby full")
                            return
                        }
                        self.gameLobby = gameLobbyObj
                        self.performSegue(withIdentifier: self.joinLobbySegue, sender: self)
                    }
                }
            } else {
                self.showJoinLobbyAlert(message: "Invalid lobby code, please try again")
                return
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == joinLobbySegue,
            let destination = segue.destination as? JoinLobbyVC {
            destination.gameLobby = gameLobby
        }
    }
}

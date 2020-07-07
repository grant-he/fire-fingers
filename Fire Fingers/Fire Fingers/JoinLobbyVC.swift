//
//  Project: Fire-Fingers
//  Filename: JoinLobbyVC.swift
//  EID: gh22593 + gwe272
//  Course: CS371L
//
//  Created by Grant He & Garrett Egan on 6/30/20.
//  Copyright © 2020 G + G. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class JoinLobbyVC: UIViewController {
    
    private let playSegue = "JoinLobbyToPlaySegue"
    
    // database
    private let db = Firestore.firestore()
    
    // Player container
    private var players: [Player] = []
    
    // listens for changes to lobbies section of database
    private var playersListener: ListenerRegistration?

    // reference to players collection of lobby
    private var playersReference: CollectionReference!
    
    // chat Lobby for this lobby
    private var chatLobby: ChatLobby!

    // ChatViewController of chat view
    private var chatViewController: ChatViewController!
    
    var gameLobby: GameLobby!
    
    var player: Player!
    var playerReady = false
    var playerReference: DocumentReference!
    
    @IBOutlet weak var chatContainerView: UIView!
    
    @IBOutlet weak var lobbyCodeTextView: UITextView!
    @IBOutlet weak var instantDeathModeLabel: UILabel!
    @IBOutlet weak var earthquakeModeLabel: UILabel!
    @IBOutlet weak var emojiPromptsLabel: UILabel!
    @IBOutlet weak var playersAllowedLabel: UILabel!
    @IBOutlet weak var playersReadyLabel: UILabel!
    @IBOutlet weak var readyButton: UIButton!
    
    // MAKE SURE THIS WORKS EVEN IF LOBBY DELETED
    deinit {
        playersListener?.remove()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let chatLobbyRef = db.collection("chatLobbies").document(gameLobby.chatLobbyID)
        chatLobbyRef.getDocument( completion: { (document, error) in
            if let document = document, document.exists {
                let dataDescription = document.data()!
                guard let chatLobbyObj = ChatLobby(data: dataDescription) else {
                    print("Failed to create ChatLobby for lobby code \(self.gameLobby.chatLobbyID)")
                    return
                }
                self.chatLobby = chatLobbyObj
                self.createChatView()
            } else {
                print("Found game lobby \(self.gameLobby.id!) with uninitialized chat lobby \(self.gameLobby.chatLobbyID)")
                return
            }
        })
        
        // connect to db
        guard let id = gameLobby!.id else {
            navigationController?.popViewController(animated: true)
            print("failed to find game lobby id")
            return
        }
        
        // put ourself in the database
        playersReference = db.collection(["gameLobbies", id, "players"].joined(separator: "/"))
        let tempPlayer = Player(
            uuid: "",
            displayName: Auth.auth().currentUser!.isAnonymous ? "Guest" : Auth.auth().currentUser!.email!,
            icon: loggedInUserSettings[userSettingsIconAttribute] as! Int)
        playerReference = playersReference.addDocument(data: tempPlayer.representation) { error in
            if let e = error {
                print("Error saving player: \(e.localizedDescription)")
            }
        }
        player = Player(uuid: playerReference.documentID, displayName: tempPlayer.displayName, icon: tempPlayer.icon)
        playerReference.setData(player.representation)
        players.append(player)
        
        // listen for db changes
        playersListener = playersReference?.addSnapshotListener { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error listening for players updates: \(error?.localizedDescription ?? "No error")")
                return
            }
            
            snapshot.documentChanges.forEach { change in
                self.handlePlayersChange(change)
            }
        }
        
        // set label contents
        lobbyCodeTextView.text = gameLobby.id!
        instantDeathModeLabel.text = gameLobby.gameSettings.instantDeathModeEnabled ? "On" : "Off"
        earthquakeModeLabel.text = gameLobby.gameSettings.earthQuakeModeEnabled ? "On" : "Off"
        emojiPromptsLabel.text = gameLobby.gameSettings.emojisAllowed ? "On" : "Off"
        playersAllowedLabel.text = String(gameLobby.gameSettings.playersCount)
    }
    
    func createChatView() {
        // create a chat lobby and add it to the view
        let user = Auth.auth().currentUser!

        chatViewController = ChatViewController(user: user, chatLobby: chatLobby!)
        
        addChild(chatViewController)
        chatContainerView.addSubview(chatViewController.view)
        
        chatViewController.didMove(toParent: self)
        chatViewController.view.translatesAutoresizingMaskIntoConstraints = false
        chatViewController.view.topAnchor.constraint(equalTo: chatContainerView.safeAreaLayoutGuide.topAnchor).isActive = true
        chatViewController.view.leadingAnchor.constraint(equalTo: chatContainerView.leadingAnchor).isActive = true
        chatViewController.view.trailingAnchor.constraint(equalTo: chatContainerView.trailingAnchor).isActive = true
        chatViewController.view.bottomAnchor.constraint(equalTo: chatContainerView.bottomAnchor).isActive = true
    }
    
    // TODO: FIX THIS!!! ONLY CALL THIS WHEN BACK SEGUE IS CALLED
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // delete lobby when leaving the view if only player in lobby
        if players.count == 1 {
            deleteChatLobby()
            deleteGameLobby()
        } else {
            playersReference.document(player.uuid).delete()
        }
    }
    
    // Tool Tips
    @IBAction func instantDeathModeToolTipButtonPressed(_ sender: Any) {
        sendToolTipAlert(title: "Instant Death Mode", message: "Any typo will immediately end your attempt.")
    }
    
    @IBAction func earthquakeModeToolTipButtonPressed(_ sender: Any) {
        sendToolTipAlert(title: "Earthquake Mode", message: "Enables haptics for added chaos. Shaking becomes more frequent as players approach the finish. Hatari!")
    }
    
    @IBAction func emojiPromptsToolTipButtonPressed(_ sender: Any) {
        sendToolTipAlert(title: "Emoji Prompts", message: "Emojis may appear in game prompt. 😱")
    }
    
    @IBAction func playersAllowedToolTipButtonPressed(_ sender: Any) {
        sendToolTipAlert(title: "Players Allowed", message: "The maximum number of players, between 1 and 4.")
    }
    
    func sendToolTipAlert(title: String, message: String) {
        let controller = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        controller.addAction(UIAlertAction(
            title: "OK",
            style: .default,
            handler: nil
        ))
        self.present(controller, animated: true)
    }
    
    @IBAction func readyButtonPressed(_ sender: Any) {
        if playerReady {
            print("Player not ready.")
            playerReady = false
            readyButton.setTitleColor(UIColor.black, for: .normal)
            readyButton.backgroundColor = UIColor.systemGray4
        } else {
            print("Player ready!")
            playerReady = true
            readyButton.setTitleColor(UIColor.lightGray, for: .normal)
            readyButton.backgroundColor = UIColor.green
        }
        player.ready = playerReady
        playerReference.setData(player.representation)
    }
    
    // handles updates to players from the database
    private func handlePlayersChange(_ change: DocumentChange) {
        print("players changed, handling now")
        guard let player = Player(document: change.document) else {
            print("player could not be created")
            print(change.document)
            return
        }

        switch change.type {
        case .added:
            addPlayer(player)
        case .removed:
            removePlayer(player)
        case .modified:
            addPlayer(player)
        default:
            print("unexpected change type \(change.type)")
            break
        }
    }

    private func addPlayer(_ player: Player) {
        if player.uuid == "" {
            return
        }
        
        if !players.contains(player) {
            players.append(player)
            print("\(players.count) current players")
        } else {
            print("player already in players")
            players[players.firstIndex(of: player)!] = player
        }
        
        updateReadyData()
    }
    
    private func removePlayer(_ player: Player) {
        guard players.contains(player), let playerIndex = players.firstIndex(of: player) else {
            print("player is not currently in players")
            return
        }
        
        players.remove(at: playerIndex)
        print("\(players.count) current players")
        
        updateReadyData()
    }
    
    func updateReadyData() {
        // Count the number of players ready
        var numReady: Int = 0
        for aPlayer in players {
            if aPlayer.ready {
                numReady += 1
            }
        }
        // Update players ready label
        playersReadyLabel.text = String(numReady)
        
        // If all players are ready, perform segue to PlayVC
        if numReady == gameLobby.gameSettings.playersCount {
            performSegue(withIdentifier: playSegue, sender: nil)
        }
    }
    
    // do any necessary cleanup after a game is played
    func doPostGameCleanup() {
        player.currentWord = 0
        playerReference.setData(player.representation)
    }
    
    // delete the chat lobby
    private func deleteChatLobby() {
        print("Deleting chat lobby '\(gameLobby.chatLobbyID)'")
        db.document(["chatLobbies", gameLobby.chatLobbyID].joined(separator: "/")).delete()
    }
    
    // delete the game lobby
    private func deleteGameLobby() {
        print("Deleting game lobby '\(gameLobby.id!)'")
        db.document(["gameLobbies", gameLobby.id!].joined(separator: "/")).delete()
    }
    
    // when background is touched, dismiss keyboard but not inputBar
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        chatViewController.messageInputBar.inputTextView.resignFirstResponder()
        print("number of current players: \(players.count)")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Send game lobby data
        if segue.identifier == playSegue,
            let playVC = segue.destination as? PlayVC {
            playVC.gameLobby = gameLobby
        }
    }
}

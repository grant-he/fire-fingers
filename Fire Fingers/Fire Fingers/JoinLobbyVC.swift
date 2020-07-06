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
    
    var playerReference: DocumentReference!
    
    @IBOutlet weak var chatContainerView: UIView!
    
    @IBOutlet weak var lobbyCodeLabel: UILabel!
    @IBOutlet weak var instantDeathModeLabel: UILabel!
    @IBOutlet weak var earthquakeMode: UILabel!
    @IBOutlet weak var emojiPromptsLabel: UILabel!
    @IBOutlet weak var playersAllowedLabel: UILabel!
    
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
        let tempPlayer = Player(uuid: "", displayName: Auth.auth().currentUser!.isAnonymous ? "Guest" : Auth.auth().currentUser!.email!, icon: loggedInUserSettings[userSettingsIconAttribute] as! Int)
        let playerReference = playersReference.addDocument(data: tempPlayer.representation) { error in
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
        lobbyCodeLabel.text = gameLobby.id!
        instantDeathModeLabel.text = gameLobby.gameSettings.instantDeathModeEnabled ? "On" : "Off"
        earthquakeMode.text = gameLobby.gameSettings.earthQuakeModeEnabled ? "On" : "Off"
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // delete lobby when leaving the view if only player in lobby
        if players.count == 1 {
            deleteChatLobby()
            deleteGameLobby()
        }
        else {
            playersReference.document(player.uuid).delete()
        }
    }
    
    // when background is touched, dismiss keyboard but not inputBar
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        chatViewController.messageInputBar.inputTextView.resignFirstResponder()
        print("number of current players: \(players.count)")
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
        
        guard !players.contains(player) else {
            print("player already in players")
            return
        }

        players.append(player)
        print("\(players.count) current players")
        
//        need to reload view of player list
//        ... .reloadData()
    }
    
    private func removePlayer(_ player: Player) {
            guard players.contains(player), let playerIndex = players.firstIndex(of: player) else {
                print("player is not currently in players")
                return
            }

            players.remove(at: playerIndex)
            print("\(players.count) current players")
            
    //        need to reload view of player list
    //        ... .reloadData()
        }
    
    
    // do any necessary cleanup after a game is played
    func doPostGameCleanup() {
        player.currentWord = 0
        playerReference.setData(player.representation)
    }
    
    // delete our chat lobby
    private func deleteChatLobby(){
        print("Deleting chat lobby '\(gameLobby.chatLobbyID)'")
        db.document(["chatLobbies", gameLobby.chatLobbyID].joined(separator: "/")).delete()
    }
    
    // delete our chat lobby
    private func deleteGameLobby(){
        print("Deleting game lobby '\(gameLobby.id!)'")
        db.document(["gameLobbies", gameLobby.id!].joined(separator: "/")).delete()
    }
}

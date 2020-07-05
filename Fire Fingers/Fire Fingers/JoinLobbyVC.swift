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
    
    // reference to game lobbies section of database
//    private var gameLobbiesReference: CollectionReference {
//      return db.collection("gameLobbies")
//    }
    
//    // reference to chat lobbies section of database
//    private var chatLobbiesReference: CollectionReference {
//      return db.collection("chatLobbies")
//    }
    
    // Player container
    private var players: [Player] = []
    
    // listens for changes to lobbies section of database
    private var playersListener: ListenerRegistration?

    // reference to players collection of lobby
    private var playersReference: CollectionReference?
    
//    // reference to current chat lobby in db
//    private var chatLobbyReference: DocumentReference?
//
    // chat Lobby for this lobby
    private var chatLobby: ChatLobby!
//
    // ChatViewController of chat view
    private var chatViewController: ChatViewController!
    
    var gameLobby: GameLobby!
    
    var player: Player!
    
    var playerReference: DocumentReference!
    
    @IBOutlet weak var chatContainerView: UIView!
    
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
        
//        chatLobby = ChatLobby(name: "name")
//        chatLobby!.id = "PcqDKKPYTCAnAL6cz7lf"
//        gameLobby = GameLobby(chatLobbyID: chatLobby!.id!, gameSettings: GameSettings(instantDeathModeEnabled: false, earthQuakeModeEnabled: false, emojisAllowed: false, playersCount: 3))
//        gameLobby!.id = "gameLobbyId"
        // connect to db
        guard let id = gameLobby!.id else {
          navigationController?.popViewController(animated: true)
            print("failed to find game lobby id")
          return
        }
        playersReference = db.collection(["gameLobbies", id, "players"].joined(separator: "/"))
        
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
        if players.count == 0 {
            deleteChatLobby()
            deleteGameLobby()
        }
    }
    
    // when background is touched, dismiss keyboard but not inputBar
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        chatViewController.messageInputBar.inputTextView.resignFirstResponder()
    }
    
    // handles updates to players from the database
    private func handlePlayersChange(_ change: DocumentChange) {
        guard let player = Player(document: change.document) else {
            print("player could not be created")
            print(change.document)
            return
        }

        switch change.type {
            case .added:
                addPlayer(player)

            default:
                break
            }
        }

    private func addPlayer(_ player: Player) {
        guard !players.contains(player) else {
            print("player already in players")
            return
        }

        players.append(player)
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
        // TODO: Figure out why this doesn't work
        db.document(["chatLobbies", gameLobby.chatLobbyID].joined(separator: "/")).delete()
    }
    
    // delete our chat lobby
    private func deleteGameLobby(){
        print("Deleting game lobby '\(gameLobby.id!)'")
        db.document(["gameLobbies", gameLobby.id!].joined(separator: "/")).delete()
    }
}

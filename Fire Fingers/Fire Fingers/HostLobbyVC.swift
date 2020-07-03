//
//  Project: Fire-Fingers
//  Filename: HostLobbyVC.swift
//  EID: gh22593 + gwe272
//  Course: CS371L
//
//  Created by Grant He & Garrett Egan on 6/30/20.
//  Copyright © 2020 G + G. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class HostLobbyVC: UIViewController {
    private let chatLobbySegue = "ChatLobbySegue"
    
    // database
    private let db = Firestore.firestore()
    
    // reference to lobbies section of database
    private var lobbiesReference: CollectionReference {
      return db.collection("lobbies")
    }
    
    // reference to current chat lobby in db
    private var chatLobbyReference: DocumentReference?
    
    // chat Lobby for this lobby
    private var chatLobby: Lobby?
    
    // ChatViewController of chat view
    private var chatViewController: ChatViewController!
    
    // Instant Death Mode
    @IBOutlet weak var instantDeathModeToolTipButton: UIButton!
    
    // Earthquake Mode
    @IBOutlet weak var earthquakeModeToolTipButton: UIButton!
    
    // Emoji Prompts
    @IBOutlet weak var emojiPromptsToolTipButton: UIButton!
    
    // Players Allowed
    @IBOutlet weak var playersAllowedToolTipButton: UIButton!
    @IBOutlet weak var playersAllowedTextField: UITextField!
    @IBOutlet weak var playersAllowedStepper: UIStepper!
    @IBOutlet weak var chatContainerView: UIView!
    
    override func viewWillAppear(_ animated: Bool) {
        
        // create a chat lobby and add it to the view
        let user = Auth.auth().currentUser!
        chatLobby = createLobbyChat(name: "\(user.email!)'s Lobby")

        chatViewController = ChatViewController(user: user, lobby: chatLobby!)
        
        addChild(chatViewController)
        chatContainerView.addSubview(chatViewController.view)
        
        chatViewController.didMove(toParent: self)
        chatViewController.view.translatesAutoresizingMaskIntoConstraints = false
        chatViewController.view.topAnchor.constraint(equalTo: chatContainerView.safeAreaLayoutGuide.topAnchor).isActive = true
        chatViewController.view.leadingAnchor.constraint(equalTo: chatContainerView.leadingAnchor).isActive = true
        chatViewController.view.trailingAnchor.constraint(equalTo: chatContainerView.trailingAnchor).isActive = true
        chatViewController.view.bottomAnchor.constraint(equalTo: chatContainerView.bottomAnchor).isActive = true
        
        // initialize number of players
        playersAllowedStepper.value = 2
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // as host, delete lobby when leaving the host view
        deleteLobbyChat()
    }
    
    @IBAction func instantDeathModeUpdated(_ sender: Any) {
    }
    
    @IBAction func earthquakeModeUpdated(_ sender: Any) {
    }
    
    @IBAction func emojiPromptsUpdated(_ sender: Any) {
    }
    
    @IBAction func playersAllowedTextFieldUpdated(_ sender: Any) {
        
        if let newValue: Int = Int(playersAllowedTextField.text ?? "0") {
            // If new value is too small, send an alert
            if newValue < Int(playersAllowedStepper.minimumValue) {
                playersAllowedValueOutOfBoundsHandler(tooLarge: false)
            }
            // If new value is too large, send an alert
            else if newValue > Int(playersAllowedStepper.maximumValue) {
                playersAllowedValueOutOfBoundsHandler(tooLarge: true)
            }
            // If valid value, update stepper to reflect changes
            else {
                playersAllowedStepper.value = Double(newValue)
            }
        }
    }
    
    func playersAllowedValueOutOfBoundsHandler(tooLarge: Bool) {
        
        var title = "Inputted value too small"
        if tooLarge {
            title = "Inputted value too large"
        }
        
        let controller = UIAlertController(
            title: title,
            message: "Please select a value between \(Int(playersAllowedStepper.minimumValue)) and \(Int(playersAllowedStepper.maximumValue))",
            preferredStyle: .alert
        )
        controller.addAction(UIAlertAction(
            title: "OK",
            style: .default,
            handler: nil
        ))
        self.present(controller, animated: true)
        // Reset text to stepper's value
        playersAllowedTextField.text = Int(playersAllowedStepper.value).description
    }
    
    @IBAction func playersAllowedUpdated(_ sender: Any) {
        // Update text field to reflect changes
        self.playersAllowedTextField.text = Int(playersAllowedStepper.value).description
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
    
    // when background is touched, dismiss keyboard but not inputBar
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        chatViewController.messageInputBar.inputTextView.resignFirstResponder()
    }

    // create a new chat lobby
    private func createLobbyChat(name:String) -> Lobby{
        print("Creating chat lobby '\(name)")
        var lobby = Lobby(name: name)
        chatLobbyReference = lobbiesReference.addDocument(data: lobby.representation) { error in
            if let e = error {
                print("Error saving chat lobby: \(e.localizedDescription)")
            }
          }
        lobby.id = chatLobbyReference?.documentID
        return lobby
    }
    
    // delete our chat lobby
    private func deleteLobbyChat(){
        print("Deleting chat lobby '\(chatLobby!.name)'")
        chatLobbyReference?.delete()
    }
}

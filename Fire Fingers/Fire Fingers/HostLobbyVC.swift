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
    let joinLobbySegue = "JoinLobbySegue"
    
    // database
    private let db = Firestore.firestore()
    
    // chat Lobby for this lobby
    private var gameLobby: GameLobby?
    
    // Instant Death Mode
    @IBOutlet weak var instantDeathModeSwitch: UISwitch!
    
    // Earthquake Mode
    @IBOutlet weak var earthQuakeModeSwitch: UISwitch!
    
    // Emoji Prompts
    @IBOutlet weak var emojiPromptsSwitch: UISwitch!
    
    // Players Allowed
    
    @IBOutlet weak var playersAllowedTextField: UITextField!
    @IBOutlet weak var playersAllowedStepper: UIStepper!
    
    override func viewWillAppear(_ animated: Bool) {
        
        // initialize number of players
        playersAllowedStepper.value = 2
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
    
    @IBAction func createLobbyButtonPressed(_ sender: Any) {
        gameLobby = createGameLobby()
        performSegue(withIdentifier: joinLobbySegue, sender: self)
    }

    // create a new game lobby
    private func createGameLobby() -> GameLobby {
        let chatLobby = createChatLobby()
        
        print("Creating game lobby")
        let gameSettings = GameSettings(instantDeathModeEnabled: instantDeathModeSwitch.isOn, earthQuakeModeEnabled: earthQuakeModeSwitch.isOn, emojisAllowed: emojiPromptsSwitch.isOn, playersCount: Int(playersAllowedTextField.text!)!)
        let lobby = GameLobby(chatLobbyID: chatLobby.id!, gameSettings: gameSettings)
        let gameLobbyReference = db.collection("gameLobbies").addDocument(data: lobby.representation) { error in
            if let e = error {
                print("Error saving chat lobby: \(e.localizedDescription)")
            }
          }
        lobby.id = gameLobbyReference.documentID
        gameLobbyReference.setData(lobby.representation)
        print("game lobby id: \(String(describing: lobby.id))")
        return lobby
    }
    
    // create a new chat lobby
    private func createChatLobby() -> ChatLobby{
        print("Creating chat lobby")
        let lobby = ChatLobby()
        let chatLobbyReference = db.collection("chatLobbies").addDocument(data: lobby.representation) { error in
            if let e = error {
                print("Error saving chat lobby: \(e.localizedDescription)")
            }
          }
        lobby.id = chatLobbyReference.documentID
        chatLobbyReference.setData(lobby.representation)
        return lobby
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == joinLobbySegue,
            let destination = segue.destination as? JoinLobbyVC {
            destination.gameLobby = gameLobby
        }
    }
}

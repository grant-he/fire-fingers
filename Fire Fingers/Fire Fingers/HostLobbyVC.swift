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
    
    private let joinLobbySegue = "JoinLobbySegue"
    
    // Database
    private let db = Firestore.firestore()
    
    // Lobby stuff
    private var gameLobby: GameLobby?
    private var chatLobby: ChatLobby?
    private var emojiPrompts: Bool!
    private var prompt: Prompt?
    
    // Instant Death Mode
    @IBOutlet weak var instantDeathModeSwitch: UISwitch!
    // Earthquake Mode
    @IBOutlet weak var earthQuakeModeSwitch: UISwitch!
    // Emoji Prompts
    @IBOutlet weak var emojiPromptsSwitch: UISwitch!
    // Players Allowed
    @IBOutlet weak var playersAllowedTextField: UITextField!
    @IBOutlet weak var playersAllowedStepper: UIStepper!
    
    @IBOutlet weak var createLobbyButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize number of players
        playersAllowedStepper.value = 2
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let appropriateTitleColor: UIColor = MainVC.findAppropriateTitleColor()
        createLobbyButton.setTitleColor(appropriateTitleColor, for: .normal)
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
        createGameLobby()
    }

    // create a new game lobby
    private func createGameLobby() {
        createChatLobby()
        print("Creating game lobby")
        // Find appropriate prompt
        self.emojiPrompts = emojiPromptsSwitch.isOn
        findAppropriatePrompt()
    }
    
    private func findAppropriatePrompt() {
        print("Finding appropriate prompt!")
        // load and process all the prompts data
        let promptsReference = self.db.collection("prompts")
        promptsReference.getDocuments() { (querySnapshot, err) in
            print("Getting documents: \(String(describing: querySnapshot.debugDescription))")
            if let e = err {
                print("Error getting documents: \(e)")
                return
            } else {
                print("Processing prompts data")
                self.processPromptsData(documents: querySnapshot!.documents)
            }
        }
    }
    
    // takes all the prompt records in the database
    func processPromptsData(documents: [QueryDocumentSnapshot]) {
        // Count up number of prompts and number of prompts without emojis
        var numPrompts: Int = 0
        var numNonEmojis: Int = 0
        for document in documents {
            guard let result = Prompt(document: document) else {
                print("failed to create Prompt for prompt from [\(document.data())], skipping")
                continue
            }
            
            if !result.hasEmojis {
                numNonEmojis += 1
            }
            numPrompts += 1
        }
        
        // If emoji prompts are available select a random prompt
        if emojiPrompts {
            var indexRemaining = Int.random(in: 0..<numPrompts)
            for document in documents {
                guard let result = Prompt(document: document) else {
                    print("failed to create Prompt for prompt from [\(document.data())], skipping")
                    continue
                }
                if indexRemaining == 0 {
                    prompt = result
                    print("Selected prompt \(String(describing: prompt))")
                    finishGameLobby()
                    return
                }
                indexRemaining -= 1
            }
        }
        // Otherwise, select a random prompt with no emojis
        else {
            var indexRemaining = Int.random(in: 0..<numNonEmojis)
            for document in documents {
                guard let result = Prompt(document: document) else {
                    print("failed to create Prompt for prompt from [\(document.data())], skipping")
                    continue
                }
                if !result.hasEmojis {
                    if indexRemaining == 0 {
                        prompt = result
                        print("Selected prompt \(String(describing: prompt))")
                        finishGameLobby()
                        return
                    }
                    indexRemaining -= 1
                }
            }
        }
    }
    
    private func finishGameLobby() {
        let gameSettings = GameSettings(instantDeathModeEnabled: instantDeathModeSwitch.isOn, earthQuakeModeEnabled: earthQuakeModeSwitch.isOn, emojisAllowed: emojiPrompts, playersCount: Int(playersAllowedTextField.text!)!)
        let lobby = GameLobby(chatLobbyID: self.chatLobby!.id!, prompt: self.prompt!, gameSettings: gameSettings)
        let gameLobbyReference = db.collection("GameLobbies").addDocument(data: lobby.representation) { error in
            if let e = error {
                print("Error saving chat lobby: \(e.localizedDescription)")
            }
        }
        lobby.id = gameLobbyReference.documentID
        gameLobbyReference.setData(lobby.representation)
        self.gameLobby = lobby
        print("game lobby id: \(String(describing: lobby.id))")
        performSegue(withIdentifier: joinLobbySegue, sender: self)
    }
    
    // create a new chat lobby
    private func createChatLobby() {
        print("Creating chat lobby")
        let lobby = ChatLobby()
        let chatLobbyReference = db.collection("chatLobbies").addDocument(data: lobby.representation) { error in
            if let e = error {
                print("Error saving chat lobby: \(e.localizedDescription)")
            }
        }
        lobby.id = chatLobbyReference.documentID
        chatLobbyReference.setData(lobby.representation)
        self.chatLobby = lobby
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == joinLobbySegue,
            let destination = segue.destination as? JoinLobbyVC {
            destination.gameLobby = self.gameLobby
        }
    }
}

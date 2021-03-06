//
//  Project: Fire-Fingers
//  Filename: PlayVC.swift
//  EID: gh22593 + gwe272
//  Course: CS371L
//
//  Created by Grant He & Garrett Egan on 6/30/20.
//  Copyright © 2020 G + G. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import AudioToolbox

class PlayVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let playerCellIdentifier = "PlayerProgessCell"
    private let returnToLobbySegue = "ReturnToLobbySegue"
    private let quitGameSegue = "QuitGameSegue"
    
    // Attributes
    private let completedAttributes = [NSAttributedString.Key.backgroundColor: UIColor.green, NSAttributedString.Key.foregroundColor: UIColor.lightGray, NSAttributedString.Key.underlineColor: UIColor.clear]
    private let correctLetterAttribute = [NSAttributedString.Key.backgroundColor: UIColor.green]
    private let clearBackgroundLetterAttribute = [NSAttributedString.Key.backgroundColor: UIColor.clear]
    private let wrongLetterAttribute = [NSAttributedString.Key.backgroundColor: UIColor.red]
    private let underlineAttribute = [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue, NSAttributedString.Key.underlineColor: UIColor.black] as [NSAttributedString.Key: Any]
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var inputField: UITextField!
    @IBOutlet weak var backButton: UIBarButtonItem!
    
    
    // Game Lobby and associated objects
    var gameLobby: GameLobby!
    var players: [Player]!
    var playerReference: DocumentReference!
    var player: Player!
    
    // Database
    private let db = Firestore.firestore()
    // Listens for changes to lobbies section of database
    private var playersListener: ListenerRegistration?
    // Reference to players collection of lobby
    private var playersReference: CollectionReference!
    
    // Prompt-related variables
    private var attributedPrompt: NSMutableAttributedString = NSMutableAttributedString()
    private var promptWords: Array<NSMutableAttributedString> = Array()
    private var currWord: NSMutableAttributedString = NSMutableAttributedString()
    private var currWordCount: Int = 0 {
        didSet {
            player.currentWord = currWordCount
            playerReference.setData(player.representation)
            // Rumble if earthquake mode is enabled
            if gameLobby.gameSettings.earthQuakeModeEnabled {
                print("*Rumble*")
                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            }
        }
    }
    private var currWordIndex: Int = 0
    private var totalPromptCharacters: Int = 0
    private var didFail: Bool = false
    
    // Timing Variables
    private var countdownAlertController: UIAlertController!
    private var countdownCounter: Int = 3
    private var countdownTimer: Timer = Timer()
    private var startingTime: DispatchTime = DispatchTime(uptimeNanoseconds: 0)
    private var endingTime: DispatchTime = DispatchTime(uptimeNanoseconds: 0)
    var currWordSemaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set up table view
        tableView.dataSource = self
        tableView.delegate = self
        
        // initialize back button text
        backButton.title = players.count == 1 ? "Back to Lobby" : "Back to Main Menu"
        
        // Set up players reference
        playersReference = db.collection(["GameLobbies", gameLobby.id!, "players"].joined(separator: "/"))
        
        // Trigger 3 second countdown timer and begin game
        showAlert()
        
        // reload game lobby in case of prompt change
        db.document("GameLobbies/\(gameLobby.id!)").getDocument(completion: { (document, error) in
            self.gameLobby = GameLobby(document: document!)

            // Set up prompt and associated calculations
            self.promptLabel.text = self.gameLobby.prompt.prompt
            self.attributedPrompt = NSMutableAttributedString(string: self.promptLabel.text!)
            self.totalPromptCharacters = self.promptLabel.attributedText!.length
            
            self.promptWords = []
            let promptWordsStrings = self.promptLabel.text!.split(separator: " ")
            for promptWordString in promptWordsStrings {
                self.promptWords.append(NSMutableAttributedString(string: String(promptWordString)))
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        
        player.completionTime = nil
        player.currentWord = 0;
        playerReference.setData(player.representation)
        
        
        // Create playersListener to listen for db changes
        playersListener = playersReference?.addSnapshotListener { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                NSLog("Error listening for players updates: \(error?.localizedDescription ?? "No error")")
                return
            }
            // Handle all player changes
            snapshot.documentChanges.forEach { change in
                self.handlePlayersChange(change)
            }
        }
    }
    
    
    @IBAction func backButtonPressed(_ sender: Any) {
        // can only return to the lobby if you are done with the
        // prompt or you are the only player in the lobby
        // otherwise you will go back to the main menu
        if player.completionTime != nil || players.count == 1 {
            
            if allPlayersCompleted() {
                findAppropriatePrompt()
            } else {
                navigationController?.popViewController(animated: true)
            }
        } else {
            db.collection("chatLobbies/\(gameLobby.chatLobbyID)/thread").addDocument(data: Message(sender: FireFingersSender(senderId: "System", displayName: "System"), content: "\(player.displayName) left the lobby.").representation)
            playersReference.document(player.uuid).delete()
            navigationController?.popToRootViewController(animated: true)
        }
    }
    
    private func allPlayersCompleted() -> Bool {
        for aPlayer in players {
            if aPlayer.completionTime == nil, aPlayer != player {
                return false
            }
        }
        return true
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
                print("failed to create Prompt, skipping")
                continue
            }
            
            if !result.hasEmojis {
                numNonEmojis += 1
            }
            numPrompts += 1
        }
        
        // If emoji prompts are available select a random prompt
        if gameLobby.gameSettings.emojisAllowed {
            var indexRemaining = Int.random(in: 0..<numPrompts)
            for document in documents {
                guard let result = Prompt(document: document) else {
                    print("failed to create Prompt, skipping")
                    continue
                }
                if indexRemaining == 0 {
                    gameLobby.prompt = result
                    let reference = db.document("GameLobbies/\(gameLobby.id!)")
                    reference.setData(gameLobby.representation)
                    print("Selected prompt \(gameLobby.prompt.prompt)")
                    navigationController?.popViewController(animated: true)
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
                    print("failed to create Prompt, skipping")
                    continue
                }
                if !result.hasEmojis {
                    if indexRemaining == 0 {
                        gameLobby.prompt = result
                        let reference = db.document("GameLobbies/\(gameLobby.id!)")
                        reference.setData(gameLobby.representation)
                        print("Selected prompt \(gameLobby.prompt.prompt)")
                        navigationController?.popViewController(animated: true)
                        return
                    }
                    indexRemaining -= 1
                }
            }
        }
    }
    
//    private func deleteGameLobby() {
//        // delete the chat lobby
//        print("Deleting chat lobby '\(gameLobby.chatLobbyID)'")
//        db.document(["chatLobbies", gameLobby.chatLobbyID].joined(separator: "/")).delete()
//        
//        // delete the game lobby
//        print("Deleting game lobby '\(gameLobby.id!)'")
//        db.document(["GameLobbies", gameLobby.id!].joined(separator: "/")).delete()
//    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        playersListener?.remove()
    }
    
    func showAlert() {
        // Create countdown alert controller
        self.countdownAlertController = UIAlertController(title: "Countdown:", message: String(self.countdownCounter), preferredStyle: .alert)
        self.countdownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.countdown), userInfo: nil, repeats: true)
        self.present(self.countdownAlertController, animated: true)
    }
    
    func startGame() {
        // Game has begun. Mark starting time.
        print("Starting Game!")
        startingTime = DispatchTime.now()
        for promptWord in promptWords {
            print("promptWord is \(promptWord.string)")
            // New word should have space appended unless it's the final word
            if currWordCount != promptWords.count - 1 {
                currWord = promptWord
                currWord.append(NSAttributedString(string: " "))
            } else {
                currWord = promptWord
            }
            print("promptWord count is \(promptWord.length)")
            print("currWordIndex is \(currWordIndex)")
            attributedPrompt.addAttributes(underlineAttribute, range: NSRange(location: currWordIndex, length: promptWord.length))
            print("New word: \(currWord.string)")
            // Wait until new word has been inputted
            currWordSemaphore.wait()
            
            // check if they failed in instant death mode
            if didFail {
                print("they failed, breaking")
                break
            }
        }
        // All prompt words have been completed. Mark ending time and calculate duration of race.
        endingTime = DispatchTime.now()
        let difference = Double(endingTime.uptimeNanoseconds - startingTime.uptimeNanoseconds) / 1_000_000_000
        // Handle race completion
        completeRace(duration: difference)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return players.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: playerCellIdentifier, for: indexPath as IndexPath) as! PlayerProgressViewCell
        let aPlayer = players[indexPath.row]
        
        // Calculate fraction of prompt complete, by number of words completed
        let progressFraction: Float = Float(aPlayer.currentWord) / Float(self.gameLobby.prompt.numWords)
        // Name label should show player's name
        cell.playerNameLabel?.text = aPlayer.displayName
        // Image should show player's icon at current prompt progress
        let progressFrame = cell.playerProgress.frame
        
        // status
        if aPlayer.completionTime == nil {
            cell.playerWPMLabel.text = "still typing..."
        } else if aPlayer.currentWord < gameLobby.prompt.numWords {
                assert(gameLobby.gameSettings.instantDeathModeEnabled)
                cell.playerWPMLabel.text = "failed"
        } else {
            cell.playerWPMLabel.text = String(format: "%.2f wpm", (Double(gameLobby.prompt.numWords) / aPlayer.completionTime!) * 60.0)
        }
        cell.playerProgressImage?.center = CGPoint(x: CGFloat(progressFrame.minX+progressFrame.width*CGFloat(progressFraction)), y: progressFrame.midY)
        cell.playerProgressImage?.image = UIImage(named: "icon\(aPlayer.icon)\(loggedInUserSettings[userSettingsDarkModeAttribute] as! Bool ? "_dark" : "" )")
        // Progress view should show current prompt progress
        cell.playerProgress?.setProgress(progressFraction, animated: true)
        
        return cell
    }
    
    @objc func countdown() {
        // Decrement countdown counter every time function is called
        // Alert controller displays different message depending on countdown counter
        if self.countdownCounter > 0 {
            self.countdownAlertController.message = String(self.countdownCounter)
            if self.countdownCounter > 1 {
                SettingsVC.playMP3File(forResource: "racing_beep")
            }
        } else if self.countdownCounter == 0 {
            self.countdownAlertController.message = "Go!!!!"
        } else {
            // Start game when counter becomes negative
            self.countdownAlertController.dismiss(animated: true, completion: {
                self.countdownTimer.invalidate()
                DispatchQueue.global(qos: .userInteractive).async {
                    self.startGame()
                }
            })
        }
        self.countdownCounter -= 1
    }
    
    @IBAction func inputFieldChanged(_ sender: Any) {
        
        if let inputText = inputField.text {
            // Calculate number of characters in which input text is equivalent to current word
        let upToCorrect = self.upToCorrect(inputText: inputText)
            print("up to correct \(upToCorrect)")
            // Is input text equivalent to current word?
            if upToCorrect == currWord.length {
                // Play correct word sound effect
                SettingsVC.playMP3File(forResource: "pop")
                print("YOU GOT IT")
                currWordCount += 1
                // Modify prompt to reflect completed word
                attributedPrompt.setAttributes(completedAttributes, range: NSRange(location: currWordIndex, length: currWord.length))
                promptLabel.attributedText = attributedPrompt
                currWordIndex += currWord.length
                // Clear input field
                inputField.text = ""
                // Release next word.
                currWordSemaphore.signal()
            } else {
                // Calculate constants for attribute marking
                let currWordToPromptEndLength = totalPromptCharacters - currWordIndex
                let currWordToLastCorrectLength = upToCorrect
                let wrongStartIndex = currWordIndex + upToCorrect
                var lastCorrectToInputEndLength = inputText.count - upToCorrect
                lastCorrectToInputEndLength = min(lastCorrectToInputEndLength, currWordToPromptEndLength-currWordToLastCorrectLength)
                
                // Clear attributes up to end of prompt before marking correct and wrong letters
                attributedPrompt.addAttributes(clearBackgroundLetterAttribute, range: NSRange(location: currWordIndex, length: currWordToPromptEndLength))
                attributedPrompt.addAttributes(correctLetterAttribute, range: NSRange(location: currWordIndex, length: currWordToLastCorrectLength))
                if lastCorrectToInputEndLength > 0 {
                    
                    // its too bad
                    if !gameLobby.gameSettings.emojisAllowed {
                        attributedPrompt.addAttributes(wrongLetterAttribute, range: NSRange(location: wrongStartIndex, length: lastCorrectToInputEndLength))
                    }
                    if gameLobby.gameSettings.instantDeathModeEnabled {
                        didFail = true
                        currWordSemaphore.signal()
                    }
                }
            }
        }
        
        promptLabel.attributedText = attributedPrompt
    }
    
    // Find the number of characters in inputText equivalent to currWord
    func upToCorrect(inputText: String) -> Int {
        
        var index: Int = 0
        while index < inputText.count && index < currWord.string.count && currWord.string[index] == inputText[index] {
            index += 1
        }
        
        return index
    }
    
    func completeRace(duration: Double) {
        
        DispatchQueue.main.async {
            self.inputField.isUserInteractionEnabled = false
        }
        
        // Play victory sound
        SettingsVC.playMP3File(forResource: "positive_tone_001")
        // Upload the game stats if the user is logged in
        // and it was a standard game
        if !Auth.auth().currentUser!.isAnonymous,
            !gameLobby.gameSettings.earthQuakeModeEnabled,
            !gameLobby.gameSettings.instantDeathModeEnabled,
            !gameLobby.gameSettings.emojisAllowed
            {
            let gameStatsReference = db.collection("GameResults")
            gameStatsReference.addDocument(data: GameResult(user: Auth.auth().currentUser!.email!, wordCount: gameLobby.prompt.numWords, time: duration).representation)
        }
        // Present game completion alert
        DispatchQueue.main.async {
            let controller = UIAlertController(
                title: "You \(self.didFail ? "failed" : "completed") the race!",
                message: "It only took \(duration) seconds.",
                preferredStyle: .alert
            )
            controller.addAction(UIAlertAction(
                title: "OK",
                style: .default,
                handler: nil
            ))
            self.present(controller, animated: true)
        }
        
        // send our time to the other players
        player.completionTime = duration
        playerReference.setData(player.representation)
        
        // allow returning to lobby
        backButton.title = "Back to Lobby"
    }
    
    // Handle updates to players from the database
    private func handlePlayersChange(_ change: DocumentChange) {
        print("Players changed: handling now")
        guard let player = Player(document: change.document) else {
            print("player could not be created")
            print(change.document)
            return
        }
        
        // Consider different change types
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
    
    // Handle player when it has been added or modified
    private func addPlayer(_ player: Player) {
        if player.uuid == "" {
            return
        }
        // Add player to players if it doesn't already exist
        if !players.contains(player) {
            players.append(player)
            print("add playvc \(player.displayName): \(players.count) current players")
        } else {
            print("player already in players")
            players[players.firstIndex(of: player)!] = player
        }
        // Reload table view data
        tableView.reloadData()
    }
    
    // Handle player when it has been removed
    private func removePlayer(_ player: Player) {
        guard players.contains(player), let playerIndex = players.firstIndex(of: player) else {
            print("player is not currently in players")
            return
        }
        // Remove player from players and reload views
        players.remove(at: playerIndex)
        print("remove playvc \(player.displayName): \(players.count) current players")
        
        if players.count == 1 {
            backButton.title = "Back to Lobby"
        }
        tableView.reloadData()
    }
}

private extension NSMutableAttributedString {
    func components(separatedBy separator: String) -> [NSMutableAttributedString] {
        var result = [NSMutableAttributedString]()
        let separatedStrings = string.components(separatedBy: separator)
        var range = NSRange(location: 0, length: 0)
        for string in separatedStrings {
            range.length = string.count
            let attributedString = NSMutableAttributedString(attributedString: attributedSubstring(from: range))
            result.append(attributedString)
            range.location += range.length + separator.count
        }
        return result
    }
}

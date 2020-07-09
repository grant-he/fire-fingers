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
    private let underlineAttribute = [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue, NSAttributedString.Key.underlineColor: UIColor.black] as [NSAttributedString.Key : Any]
    
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
    private var promptWords: Array<Substring> = Array()
    private var currWord: Substring = ""
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
        playersReference = db.collection(["gameLobbies", gameLobby.id!, "players"].joined(separator: "/"))
        print("Number of players: \(players.count)")
        
        // Trigger 3 second countdown timer and begin game
        showAlert()
        // Set up prompt and associated calculations
        promptLabel.text = gameLobby.prompt.prompt
        attributedPrompt = NSMutableAttributedString(string: promptLabel.text!)
        totalPromptCharacters = promptLabel.text!.count
        promptWords = promptLabel.text!.split(separator: " ")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Create playersListener to listen for db changes
        playersListener = playersReference?.addSnapshotListener { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error listening for players updates: \(error?.localizedDescription ?? "No error")")
                return
            }
            // Handle all player changes
            snapshot.documentChanges.forEach { change in
                self.handlePlayersChange(change)
            }
        }
    }
    
    
    @IBAction func backButtonPressed(_ sender: Any) {
        print("backButton clicked")
        
        // can only return to the lobby if you are done with the
        // prompt or you are the only player in the lobby
        // otherwise you will go back to the main menu
        if player.completionTime != nil || players.count == 1 {
            navigationController?.popViewController(animated: true)
        } else {
            playersReference.document(player.uuid).delete()
            navigationController?.popToRootViewController(animated: true)
        }
    }
    
    
    private func deleteGameLobby() {
        // delete the chat lobby
        print("Deleting chat lobby '\(gameLobby.chatLobbyID)'")
        db.document(["chatLobbies", gameLobby.chatLobbyID].joined(separator: "/")).delete()
        
        // delete the game lobby
        print("Deleting game lobby '\(gameLobby.id!)'")
        db.document(["gameLobbies", gameLobby.id!].joined(separator: "/")).delete()
    }
    
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
            // New word should have space appended unless it's the final word
            if currWordCount != promptWords.count - 1 {
                currWord = promptWord + " "
            } else {
                currWord = promptWord
            }
            attributedPrompt.addAttributes(underlineAttribute, range: NSRange(location: currWordIndex, length: promptWord.count))
            print("New word: \(currWord)")
            // Wait until new word has been inputted
            currWordSemaphore.wait()
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
        cell.playerProgressImage?.center = CGPoint(x: CGFloat(progressFrame.minX+progressFrame.width*CGFloat(progressFraction)), y: progressFrame.midY)
        cell.playerProgressImage?.image = UIImage(named: "icon\(aPlayer.icon)")
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
            // Is input text equivalent to current word?
            if upToCorrect == currWord.count {
                // Play correct word sound effect
                SettingsVC.playMP3File(forResource: "pop")
                print("YOU GOT IT")
                currWordCount += 1
                // Modify prompt to reflect completed word
                attributedPrompt.setAttributes(completedAttributes, range: NSRange(location: currWordIndex, length: currWord.count))
                promptLabel.attributedText = attributedPrompt
                currWordIndex += currWord.count
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
                    attributedPrompt.addAttributes(wrongLetterAttribute, range: NSRange(location: wrongStartIndex, length: lastCorrectToInputEndLength))
                }
            }
        }
        
        promptLabel.attributedText = attributedPrompt
    }
    
    // Find the number of characters in inputText equivalent to currWord
    func upToCorrect(inputText: String) -> Int {
        
        var index: Int = 0
        
        while index < inputText.count && index < currWord.count && currWord[index] == inputText[index] {
            index += 1
        }
        
        return index
    }
    
    func completeRace(duration: Double) {
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
                title: "You completed the race!",
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
            print("\(players.count) current players")
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
        print("\(players.count) current players")
        
        if players.count == 1 {
            backButton.title = "Back to Lobby"
        }
        tableView.reloadData()
    }
}


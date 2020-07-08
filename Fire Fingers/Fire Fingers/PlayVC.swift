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

class PlayVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let playerCellIdentifier = "PlayerProgessCell"
    
    // Attributes
    private let completedAttributes = [NSAttributedString.Key.backgroundColor: UIColor.green, NSAttributedString.Key.foregroundColor: UIColor.lightGray, NSAttributedString.Key.underlineColor: UIColor.clear]
    private let correctLetterAttribute = [NSAttributedString.Key.backgroundColor: UIColor.green]
    private let clearBackgroundLetterAttribute = [NSAttributedString.Key.backgroundColor: UIColor.clear]
    private let wrongLetterAttribute = [NSAttributedString.Key.backgroundColor: UIColor.red]
    private let underlineAttribute = [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue, NSAttributedString.Key.underlineColor: UIColor.black] as [NSAttributedString.Key : Any]
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var inputField: UITextField!
    
    // Game Lobby and related objects
    var gameLobby: GameLobby!
    var players: [Player]!
    var player: Player!
    var playerReference: DocumentReference!
    
    // Prompt-related variables
    private var attributedPrompt: NSMutableAttributedString = NSMutableAttributedString()
    private var promptWords: Array<Substring> = Array()
    private var currWord: Substring = ""
    private var currWordCount: Int = 0 {
        didSet {
            player.currentWord = currWordCount
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
        
        print("PlayVC loaded")
        
        // Check all players are here
        
        // Trigger 3 second countdown timer
        showAlert()
        
        // Begin game!!
        
        promptLabel.text = gameLobby.prompt.prompt
        attributedPrompt = NSMutableAttributedString(string: promptLabel.text!)
        
        totalPromptCharacters = promptLabel.text!.count
        promptWords = promptLabel.text!.split(separator: " ")
    }
    
    func showAlert() {
        self.countdownAlertController = UIAlertController(title: "Countdown:", message: String(self.countdownCounter), preferredStyle: .alert)
        self.countdownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.countdown), userInfo: nil, repeats: true)
        self.present(self.countdownAlertController, animated: true)
    }
    
    func startGame() {
        print("Starting Game!")
        startingTime = DispatchTime.now()
        for promptWord in promptWords {
            if currWordCount != promptWords.count - 1 {
                currWord = promptWord + " "
            } else {
                currWord = promptWord
            }
            attributedPrompt.addAttributes(underlineAttribute, range: NSRange(location: currWordIndex, length: promptWord.count))
            print("New word: \(currWord)")
            currWordSemaphore.wait()
        }
        endingTime = DispatchTime.now()
        let difference = Double(endingTime.uptimeNanoseconds - startingTime.uptimeNanoseconds) / 1_000_000_000
        completeRace(duration: difference)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return players.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: playerCellIdentifier, for: indexPath as IndexPath)
        return cell
    }
    
    @objc func countdown() {
        print("Counting down!")
        if self.countdownCounter > 0 {
            self.countdownAlertController.message = String(self.countdownCounter)
        } else if self.countdownCounter == 0 {
            self.countdownAlertController.message = "Go!!!!"
        } else {
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
                currWordCount += 1
                attributedPrompt.setAttributes(completedAttributes, range: NSRange(location: currWordIndex, length: currWord.count))
                promptLabel.attributedText = attributedPrompt
                currWordIndex += currWord.count
                
//                player.currentWord += 1
//                playerReference.setData(player.representation)
                
                inputField.text = ""
                
                print("YOU GOT IT")
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
    
    // Finds the number of characters in inputText equivalent to currWord
    func upToCorrect(inputText: String) -> Int {
        
        var index: Int = 0
        
        while index < inputText.count && index < currWord.count && currWord[index] == inputText[index] {
            index += 1
        }
        
        return index
    }
    
    func completeRace(duration: Double) {
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
        DispatchQueue.main.async {
            self.present(controller, animated: true)
        }
    }
}

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
    private var players: [Player] = []
    
    // Prompt-related variables
    private var attributedPrompt: NSMutableAttributedString = NSMutableAttributedString()
    private var promptWords: Array<Substring> = Array()
    private var currWord: Substring = ""
    private var currWordCount: Int = 0
    private var currWordIndex: Int = 0
    private var totalPromptCharacters: Int = 0
    
    // Timing Variables
    private var startingTime: DispatchTime = DispatchTime(uptimeNanoseconds: 0)
    private var endingTime: DispatchTime = DispatchTime(uptimeNanoseconds: 0)
    
    let currWordGroup: DispatchGroup = DispatchGroup()
    
    override func viewDidLoad() {
        print("HII!!")
        super.viewDidLoad()
        
        // Check all players are here
        
        // Trigger 3 second countdown timer
        
        // Begin game!!
        startingTime = DispatchTime.now()
        
        // for debugging
        promptLabel.text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
        attributedPrompt = NSMutableAttributedString(string: promptLabel.text!)
        
        totalPromptCharacters = promptLabel.text!.count
        promptWords = promptLabel.text!.split(separator: " ")
        DispatchQueue.global(qos: .userInteractive).async {
            self.startGame()
        }
    }
    
    func startGame() {
        for promptWord in promptWords {
            currWordGroup.enter()
            if currWordCount != promptWords.count - 1 {
                currWord = promptWord + " "
            } else {
                currWord = promptWord
            }
            attributedPrompt.addAttributes(underlineAttribute, range: NSRange(location: currWordIndex, length: promptWord.count))
            print("New word: \(currWord)")
            currWordGroup.wait()
        }
        endingTime = DispatchTime.now()
        let difference = Double(endingTime.uptimeNanoseconds - startingTime.uptimeNanoseconds) / 1_000_000_000
        print("YOU DID IT~!!! It only took \(difference) seconds.")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return players.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: playerCellIdentifier, for: indexPath as IndexPath)
        return cell
    }
    
    @IBAction func inputFieldChanged(_ sender: Any) {
        print("Input field changed... still looking for \(currWord)")
        
        if let inputText = inputField.text {
            
            let upToCorrect = self.upToCorrect(inputText: inputText)
            
            if upToCorrect == currWord.count {
                currWordCount += 1
                attributedPrompt.setAttributes(completedAttributes, range: NSRange(location: currWordIndex, length: currWord.count))
                promptLabel.attributedText = attributedPrompt
                currWordIndex += currWord.count
                
                inputField.text = ""
                print("LETS'S GO")
                currWordGroup.leave()
            } else {
                
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
}

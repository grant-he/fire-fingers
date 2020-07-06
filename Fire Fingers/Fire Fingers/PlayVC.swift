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
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var inputField: UITextField!
    
    // Player container
    private var players: [Player] = []
    
    private var promptWords: Array<Substring> = Array()
    private var currWord: Substring = ""
    private var currWordCount: Int = 0
    let currWordGroup: DispatchGroup = DispatchGroup()
    
    override func viewDidLoad() {
        print("HII!!")
        super.viewDidLoad()
        
        // Check all players are here
        
        // Trigger 3 second countdown timer
        
        // Begin game!!
        
        // for debugging
        promptLabel.text = "hi ho howdy hip!"
        
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
            print("New word: \(currWord)")
            currWordGroup.wait()
        }
        print("YOU DID IT~!!!")
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
            if inputText == currWord {
                currWordCount += 1
                inputField.text = ""
                print("LETS'S GO")
                currWordGroup.leave()
            }
        }
        
    }
    
}

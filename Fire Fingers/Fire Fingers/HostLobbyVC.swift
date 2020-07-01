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

class HostLobbyVC: UIViewController {

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
    
    // Enable tapping on the background to remove software keyboard
    func textFieldShouldReturn(textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

}

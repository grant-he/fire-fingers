//
//  Project: Fire-Fingers
//  Filename: MainVC.swift
//  EID: gh22593 + gwe272
//  Course: CS371L
//
//  Created by Grant He & Garrett Egan on 6/27/20.
//  Copyright © 2020 G + G. All rights reserved.
//

import UIKit
import FirebaseAuth

// Current user settings
var loggedInUserSettings: Dictionary<String, Any> = [
    "username": "guest",
    "darkModeEnabled": false,
    "volume": Float(1.0),
    "icon": "icon1.png"]

class MainVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Retrieve user settings data from core data
    }

}


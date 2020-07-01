//
//  Project: Fire-Fingers
//  Filename: MainVC.swift
//  EID: gh22593 + gwe272
//  Course: CS371L
//
//  Created by Grant He & Garrett Egan on 6/27/20.
//  Copyright © 2020 G + G. All rights reserved.
//

import FirebaseAuth
import UIKit

// Current user settings
var loggedInUserSettings: Dictionary<String, Any> = [:]

// Property names
let userSettingsEntityName = "UserSettings"
let userSettingsUsernameAttribute = "username"
let userSettingsDarkModeAttribute = "darkModeEnabled"
let userSettingsVolumeAttribute = "volume"
let userSettingsIconAttribute = "icon"

class MainVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

}

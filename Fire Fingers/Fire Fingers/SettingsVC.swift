//
//  Project: Fire-Fingers
//  Filename: SettingsVC.swift
//  EID: gh22593 + gwe272
//  Course: CS371L
//
//  Created by Grant He & Garrett Egan on 6/30/20.
//  Copyright © 2020 G + G. All rights reserved.
//

import CoreData
import FirebaseAuth
import UIKit

class SettingsVC: UIViewController {
    
    private let goToLoginSegueIdentifier = "GoToLoginSegue"

    @IBOutlet weak var darkModeSwitch: UISwitch!
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var iconOneButton: UIButton!
    @IBOutlet weak var iconTwoButton: UIButton!
    @IBOutlet weak var iconThreeButton: UIButton!
    @IBOutlet weak var logOutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        iconOneButton.layer.borderWidth = 2
        iconTwoButton.layer.borderWidth = 2
        iconThreeButton.layer.borderWidth = 2
        clearIconSelection()
        if loggedInUserSettings[userSettingsUsernameAttribute] as! String == "guest" {
            logOutButton.setTitle("Log in", for: .normal)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("Changing setting objects")
        // Update objects to match user settings
        // Dark Mode Switch:
        let darkModeEnabled = loggedInUserSettings[userSettingsDarkModeAttribute] as! Bool
        darkModeSwitch.setOn(darkModeEnabled, animated: false)
        // Volume Slider:
        let volumeLevel = loggedInUserSettings[userSettingsVolumeAttribute] as! Float
        volumeSlider.setValue(volumeLevel, animated: false)
        // Icon Buttons:
        switch loggedInUserSettings[userSettingsIconAttribute] as! String {
        case "icon1.png":
            iconOneButton.layer.borderColor = CGColor(srgbRed: 0, green: 0, blue: 255, alpha: 1)
        case "icon2.png":
            iconTwoButton.layer.borderColor = CGColor(srgbRed: 0, green: 0, blue: 255, alpha: 1)
        case "icon3.png":
            iconThreeButton.layer.borderColor = CGColor(srgbRed: 0, green: 0, blue: 255, alpha: 1)
        default:
            print("Icon Selection Error")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // If user is not guest, update core data to match current user settings
        if loggedInUserSettings[userSettingsUsernameAttribute] as! String != "guest" {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: userSettingsEntityName)
            
            var fetchedResults: [NSManagedObject]? = nil
            // Filter to only select entities matching current user
            let predicate = NSPredicate(format: "\(userSettingsUsernameAttribute) MATCHES '\(loggedInUserSettings[userSettingsUsernameAttribute]!)'")
            request.predicate = predicate
            
            do {
                try fetchedResults = context.fetch(request) as? [NSManagedObject]
                var settings: NSManagedObject? = fetchedResults?.first
                if settings == nil {
                    settings = NSEntityDescription.insertNewObject(forEntityName: userSettingsEntityName, into: context)
                    settings?.setValue(loggedInUserSettings[userSettingsUsernameAttribute], forKey: userSettingsUsernameAttribute)
                }
                
                // Set attribute values to new setting values
                print("Overriding stored user data for", loggedInUserSettings[userSettingsUsernameAttribute] as! String)
                settings?.setValue(loggedInUserSettings[userSettingsDarkModeAttribute], forKey: userSettingsDarkModeAttribute)
                settings?.setValue(loggedInUserSettings[userSettingsVolumeAttribute], forKey: userSettingsVolumeAttribute)
                settings?.setValue(loggedInUserSettings[userSettingsIconAttribute], forKey: userSettingsIconAttribute)
                
                print(loggedInUserSettings[userSettingsDarkModeAttribute] as! Bool)
                print(loggedInUserSettings[userSettingsVolumeAttribute]! as! Float)
                print(loggedInUserSettings[userSettingsIconAttribute]! as! String)
                // Commit the changes
                try context.save()
            } catch {
                // if an error occurs
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
    @IBAction func darkModeUpdated(_ sender: Any) {
        // Update user dark mode setting
        loggedInUserSettings[userSettingsDarkModeAttribute] = darkModeSwitch.isOn
    }
    
    @IBAction func volumeUpdated(_ sender: Any) {
        // Update user volume setting
        loggedInUserSettings[userSettingsVolumeAttribute] = volumeSlider.value
    }
    
    @IBAction func iconOneSelected(_ sender: Any) {
        // Clear icon selections
        clearIconSelection()
        // Select icon one and update user icon setting
        iconOneButton.layer.borderColor = CGColor(srgbRed: 0, green: 0, blue: 255, alpha: 1)
        loggedInUserSettings[userSettingsIconAttribute] = 0
    }
    
    @IBAction func iconTwoSelected(_ sender: Any) {
        // Clear icon selections
        clearIconSelection()
        // Select icon two and update user icon setting
        iconTwoButton.layer.borderColor = CGColor(srgbRed: 0, green: 0, blue: 255, alpha: 1)
        loggedInUserSettings[userSettingsIconAttribute] = 1
    }
    
    @IBAction func iconThreeSelected(_ sender: Any) {
        // Clear icon selections
        clearIconSelection()
        // Select icon three and update user icon setting
        iconThreeButton.layer.borderColor = CGColor(srgbRed: 0, green: 0, blue: 255, alpha: 1)
        loggedInUserSettings[userSettingsIconAttribute] = 2
    }
    
    func clearIconSelection() {
        // Set all icon button borders as clear
        iconOneButton.layer.borderColor = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0)
        iconTwoButton.layer.borderColor = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0)
        iconThreeButton.layer.borderColor = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0)
    }
    
    @IBAction func logOutButtonPressed(_ sender: Any) {
        // If user is guest, immediate proceed to login view
        if loggedInUserSettings[userSettingsUsernameAttribute] as! String == "guest" {
            self.performSegue(withIdentifier: self.goToLoginSegueIdentifier, sender: nil)
            
        }
        // Otherwise, send alert confirming log out
        else {
            let controller = UIAlertController(
                title: "Are you sure you want to log out?",
                message: nil,
                preferredStyle: .alert
            )
            controller.addAction(UIAlertAction(
                title: "Yes",
                style: .default,
                handler: { _ in
                    do {
                        try Auth.auth().signOut()
                    } catch {
                        // if an error occurs
                        let nserror = error as NSError
                        NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                        abort()
                    }
                    self.performSegue(withIdentifier: self.goToLoginSegueIdentifier, sender: nil)
                }
            ))
            controller.addAction(UIAlertAction(
                title: "Cancel",
                style: .cancel,
                handler: nil
            ))
            self.present(controller, animated: true)
        }
    }
}

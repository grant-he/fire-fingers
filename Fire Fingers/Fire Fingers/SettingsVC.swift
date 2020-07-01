//
//  SettingsVC.swift
//  Fire Fingers
//
//  Created by Grant He on 6/30/20.
//  Copyright © 2020 G + G. All rights reserved.
//

import UIKit
import FirebaseAuth
import CoreData

class SettingsVC: UIViewController {
    let userSettingsEntityName = "User Settings"
    let userSettingsUsernameAttribute = "username"
    let userSettingsDarkModeAttribute = "darkModeEnabled"
    let userSettingsVolumeAttribute = "volume"
    let userSettingsIconAttribute = "icon"
    let goToLoginSegueIdentifier = "GoToLoginSegue"

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
        let darkModeEnabled = loggedInUserSettings[userSettingsDarkModeAttribute] as! Bool
        darkModeSwitch.setOn(darkModeEnabled, animated: false)
        
        let volumeLevel = loggedInUserSettings[userSettingsVolumeAttribute] as! Float
        volumeSlider.setValue(volumeLevel, animated: false)
        
        switch loggedInUserSettings[userSettingsIconAttribute] as! String {
        case "icon1.png":
            iconOneButton.layer.borderColor = CGColor(srgbRed: 0, green: 0, blue: 255, alpha: 1)
        case "icon2.png":
            iconTwoButton.layer.borderColor = CGColor(srgbRed: 0, green: 0, blue: 255, alpha: 1)
        case "icon3.png":
            iconThreeButton.layer.borderColor = CGColor(srgbRed: 0, green: 0, blue: 255, alpha: 1)
        default:
            print("error")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if loggedInUserSettings[userSettingsUsernameAttribute] as! String != "guest" {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "UserSetting")
            
            var fetchedResults: [NSManagedObject]? = nil
            
            let predicate = NSPredicate(format: "\(userSettingsUsernameAttribute) MATCHES '\(loggedInUserSettings[userSettingsUsernameAttribute]!)'")
            request.predicate = predicate
            
            do {
                try fetchedResults = context.fetch(request) as? [NSManagedObject]
                let settings = fetchedResults?.first
                settings?.setValue(loggedInUserSettings[userSettingsDarkModeAttribute], forKey: userSettingsDarkModeAttribute)
                settings?.setValue(loggedInUserSettings[userSettingsVolumeAttribute], forKey: userSettingsVolumeAttribute)
                settings?.setValue(loggedInUserSettings[userSettingsIconAttribute], forKey: userSettingsIconAttribute)
                
                // Commit the changes
                do {
                    try context.save()
                } catch {
                    // if an error occurs
                    let nserror = error as NSError
                    NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                    abort()
                }
            } catch {
                // if an error occurs
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
    @IBAction func darkModeUpdated(_ sender: Any) {
        loggedInUserSettings[userSettingsDarkModeAttribute] = darkModeSwitch.isOn
    }
    
    @IBAction func volumeUpdated(_ sender: Any) {
        loggedInUserSettings[userSettingsVolumeAttribute] = volumeSlider.value
    }
    
    @IBAction func iconOneSelected(_ sender: Any) {
        clearIconSelection()
        
        iconOneButton.layer.borderColor = CGColor(srgbRed: 0, green: 0, blue: 255, alpha: 1)
        loggedInUserSettings[userSettingsIconAttribute] = "icon1.png"
    }
    
    @IBAction func iconTwoSelected(_ sender: Any) {
        clearIconSelection()
        
        iconTwoButton.layer.borderColor = CGColor(srgbRed: 0, green: 0, blue: 255, alpha: 1)
        loggedInUserSettings[userSettingsIconAttribute] = "icon2.png"
    }
    
    @IBAction func iconThreeSelected(_ sender: Any) {
        clearIconSelection()
        
        iconThreeButton.layer.borderColor = CGColor(srgbRed: 0, green: 0, blue: 255, alpha: 1)
        loggedInUserSettings[userSettingsIconAttribute] = "icon3.png"
    }
    
    func clearIconSelection() {
        iconOneButton.layer.borderColor = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0)
        iconTwoButton.layer.borderColor = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0)
        iconThreeButton.layer.borderColor = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0)
    }
    
    @IBAction func logOutButtonPressed(_ sender: Any) {
        if loggedInUserSettings[userSettingsUsernameAttribute] as! String == "guest" {
            self.performSegue(withIdentifier: self.goToLoginSegueIdentifier, sender: nil)
            
        } else {
            // Send alert confirming logout
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

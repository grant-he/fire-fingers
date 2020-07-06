//
//  Project: Fire-Fingers
//  Filename: LoginScreenVC.swift
//  EID: gh22593 + gwe272
//  Course: CS371L
//
//  Created by Grant He & Garrett Egan on 6/30/20.
//  Copyright © 2020 G + G. All rights reserved.
//

import CoreData
import FirebaseAuth
import UIKit

class LoginScreenVC: UIViewController {
    
    private let loginSegue = "LoginSegue"

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        // Attempt to sign in with given email and password
        if let email = emailTextField.text,
            let password = passwordTextField.text {
            Auth.auth().signIn(withEmail: email, password: password, completion: {
                (user, error) in
                // if no errors, perform segue to main view controller
                if error == nil {
                    self.retrieveUserSettings()
                    self.performSegue(withIdentifier: self.loginSegue, sender: nil)
                }
                // Otherwise, send alert of error description
                else {
                    let controller = UIAlertController(
                        title: "Login Error",
                        message: error?.localizedDescription,
                        preferredStyle: .alert
                    )
                    controller.addAction(UIAlertAction(
                        title: "OK",
                        style: .default,
                        handler: nil
                    ))
                    self.present(controller, animated: true)
                }
            })
        }
    }
    
    @IBAction func registerButtonPressed(_ sender: Any) {
        // Attempt to create new user with given email and password
        if let email = emailTextField.text,
            let password = passwordTextField.text {
            Auth.auth().createUser(withEmail: email, password: password, completion: {
                (user, error) in
                // If no error, automatically sign in and perform segue to main view controller
                if error == nil {
                    Auth.auth().signIn(withEmail: email, password: password, completion: nil)
                    self.retrieveUserSettings()
                    self.performSegue(withIdentifier: self.loginSegue, sender: nil)
                }
                // Otherwise, send alert of error description
                else {
                    let controller = UIAlertController(
                        title: "Registration Error",
                        message: error?.localizedDescription,
                        preferredStyle: .alert
                    )
                    controller.addAction(UIAlertAction(
                        title: "OK",
                        style: .default,
                        handler: nil
                    ))
                    self.present(controller, animated: true)
                }
            })
        }
    }
    
    @IBAction func continueAsGuestButtonPressed(_ sender: Any) {
        // Send alert confirming guest selection
        let controller = UIAlertController(
            title: "Continue as guest?",
            message: "Your scores will not be saved.",
            preferredStyle: .alert
        )
        controller.addAction(UIAlertAction(
            title: "Yes",
            style: .default,
            handler: { _ in
                Auth.auth().signInAnonymously(completion: {
                    (authResult, error) in
                    if error == nil {
                        self.retrieveUserSettings()
                        self.performSegue(withIdentifier: self.loginSegue, sender: nil)
                    }
                    else {
                        print(error!.localizedDescription)
                    }
                })
            }
        ))
        controller.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: nil
        ))
        self.present(controller, animated: true)
    }
    
    // Retrieve user settings data from core data
    func retrieveUserSettings() {
        if let username = Auth.auth().currentUser?.email {
            print("Retrieving data for", username)
            // Set username to user email
            loggedInUserSettings[userSettingsUsernameAttribute] = username
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: userSettingsEntityName)

            var fetchedResults: [NSManagedObject]? = nil
            // Filter to only select entities matching current user
            let predicate = NSPredicate(format: "\(userSettingsUsernameAttribute) == %@", loggedInUserSettings[userSettingsUsernameAttribute]! as! CVarArg)
            request.predicate = predicate

            do {
                try fetchedResults = context.fetch(request) as? [NSManagedObject]
                
                if fetchedResults!.count > 0 {
                    print("Fetching stored setting for", username)
                    let settings = fetchedResults?.first
                    // Set user settings to new fetched values
                    loggedInUserSettings[userSettingsDarkModeAttribute] = settings?.value(forKeyPath: userSettingsDarkModeAttribute)
                    loggedInUserSettings[userSettingsVolumeAttribute] = settings?.value(forKeyPath: userSettingsVolumeAttribute)
                    loggedInUserSettings[userSettingsIconAttribute] = settings?.value(forKeyPath: userSettingsIconAttribute)

                    // Commit the changes
                    try context.save()
                } else {
                    loggedInUserSettings[userSettingsDarkModeAttribute] = false
                    loggedInUserSettings[userSettingsVolumeAttribute] = Float(1.0)
                    loggedInUserSettings[userSettingsIconAttribute] = "icon1.png"
                }                
            } catch {
                // if an error occurs
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        } else {
            print("retrieving info as guest")
            loggedInUserSettings[userSettingsUsernameAttribute] = "guest"
            loggedInUserSettings[userSettingsDarkModeAttribute] = false
            loggedInUserSettings[userSettingsVolumeAttribute] = Float(1.0)
            loggedInUserSettings[userSettingsIconAttribute] = "icon1.png"
        }
    }
    
    // Debugging functionality: delete all results in the user settings entity
    func clearCoreData() {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: userSettingsEntityName)
        var fetchedResults: [NSManagedObject]
        
        do {
            try fetchedResults = context.fetch(request) as! [NSManagedObject]
            
            if fetchedResults.count > 0 {
                // Delete all fetched results
                for result:AnyObject in fetchedResults {
                    context.delete(result as! NSManagedObject)
                    print("\(result.value(forKey: userSettingsEntityName)!) has been deleted")
                }
            }
            try context.save()
            
        } catch {
            // if an error occurs
            let nserror = error as NSError
            NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
            abort()
        }
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

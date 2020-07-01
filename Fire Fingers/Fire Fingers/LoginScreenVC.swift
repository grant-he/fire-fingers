//
//  LoginScreenVC.swift
//  Fire Fingers
//
//  Created by Grant He on 6/30/20.
//  Copyright © 2020 G + G. All rights reserved.
//

import UIKit
import FirebaseAuth

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
                self.performSegue(withIdentifier: self.loginSegue, sender: nil)
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

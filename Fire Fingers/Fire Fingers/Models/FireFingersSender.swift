//
//  FireFingersSender.swift
//  Fire Fingers
//
//  Created by Garrett Egan on 7/1/20.
//  Copyright © 2020 G + G. All rights reserved.
//

import UIKit
import MessageKit
import Firebase

class FireFingersSender: SenderType {
    internal let senderId: String
    
    internal let displayName: String
    
    init(senderId:String, displayName:String) {
        self.senderId = senderId
        self.displayName = displayName
    }
}

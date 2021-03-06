//
//  Project: Fire-Fingers
//  Filename: Message.swift
//  EID: gh22593 + gwe272
//  Course: CS371L
//
//  Created by Grant He & Garrett Egan on 7/4/20.
//  Copyright © 2020 G + G. All rights reserved.
//
/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Firebase
import MessageKit
import FirebaseFirestore

class Message: MessageType {
    
    let id: String?
    let content: String
    let sentDate: Date
    let sender: SenderType
    
    var kind: MessageKind {
        return .attributedText(NSAttributedString(string: content, attributes: [NSAttributedString.Key.foregroundColor : MainVC.isDarkModeEnabled ? UIColor.white : UIColor.black as Any]))
    }
    
    var messageId: String {
        return id ?? UUID().uuidString
    }
    
    var image: UIImage? = nil
    var downloadURL: URL? = nil
    
    init(sender: FireFingersSender, content: String) {
        self.sender = sender
        self.content = content
        sentDate = Date()
        id = nil
    }
    
    init?(document: QueryDocumentSnapshot) {
        
        let data = document.data()
        
        guard let sentDate = (data["created"] as? Timestamp)?.dateValue() else {
            NSLog("message failed to convert created date '\(String(describing: data["created"]))'")
            return nil
        }
        
        guard let senderID = data["senderID"] as? String else {
            NSLog("message failed to convert sender id '\(String(describing: data["senderID"]))'")
            return nil
        }
        
        guard let senderName = data["senderName"] as? String else {
            NSLog("message failed to convert sender name '\(String(describing: data["senderName"]))'")
            return nil
        }
        
        id = document.documentID
        
        self.sentDate = sentDate
        sender = FireFingersSender(senderId: senderID, displayName: senderName)
        
        if let content = data["content"] as? String {
            self.content = content
            downloadURL = nil
        } else if let urlString = data["url"] as? String, let url = URL(string: urlString) {
            downloadURL = url
            content = ""
        } else {
            NSLog("message failed to convert content '\(String(describing: data["content"]))'")
            return nil
        }
    }
}

extension Message: DatabaseRepresentation {
    
    var representation: [String: Any] {
        var rep: [String: Any] = [
            "created": sentDate,
            "senderID": sender.senderId,
            "senderName": sender.displayName
        ]
        
        if let url = downloadURL {
            rep["url"] = url.absoluteString
        } else {
            rep["content"] = content
        }
        
        return rep
    }
}

extension Message: Comparable {
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
    
    static func < (lhs: Message, rhs: Message) -> Bool {
        return lhs.sentDate < rhs.sentDate
    }
  
}

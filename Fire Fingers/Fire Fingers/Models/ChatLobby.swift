//
//  Project: Fire-Fingers
//  Filename: ChatLobby.swift
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

import FirebaseFirestore

class ChatLobby {
  
    var id: String?

    init() {
        id = nil
    }
    
    init?(data: [String: Any]) {
        
        guard let id = (data["id"] as? String) else {
            print("ChatLobby failed to convert id '\(String(describing: data["id"]))'")
            return nil
        }
        
        self.id = id
    }
}

extension ChatLobby: DatabaseRepresentation {
    
    var representation: [String: Any] {
        var rep: [String: Any] = [:]
        
        if let id = id {
            rep["id"] = id
        }
        
        return rep
    }
}

//
//  Project: Fire-Fingers
//  Filename: ChatVC.swift
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

import UIKit
import Firebase
import MessageKit
import FirebaseFirestore
import InputBarAccessoryView

final class ChatViewController: MessagesViewController {
  
    // Color for send button
    let sendButtonColor = UIColor(red: 1 / 255, green: 93 / 255, blue: 48 / 255, alpha: 1)
  
    // Datatbase
    private let db = Firestore.firestore()
    
    // Reference to message thread
    private var reference: CollectionReference?

    // Message container
    private var messages: [Message] = []
    
    // listens for changes to lobbies section of database
    private var messageListener: ListenerRegistration?
  
    // Signed in auth user
    let user: User?
    
    // ChatLobby we are connected to
    let chatLobby: ChatLobby?
  
    deinit {
    messageListener?.remove()
    }

    init(user: User, chatLobby: ChatLobby) {
        self.user = user
        self.chatLobby = chatLobby
        super.init(nibName: nil, bundle: nil)
    }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // connect to db
    guard let id = chatLobby!.id else {
      navigationController?.popViewController(animated: true)
        print("failed to find chat lobby id")
      return
    }
    reference = db.collection(["chatLobbies", id, "thread"].joined(separator: "/"))
    
    // listen for db changes
    messageListener = reference?.addSnapshotListener { querySnapshot, error in
      guard let snapshot = querySnapshot else {
        print("Error listening for lobby updates: \(error?.localizedDescription ?? "No error")")
        return
      }
      
      snapshot.documentChanges.forEach { change in
        self.handleDocumentChange(change)
      }
    }
    
    // set ourself as necessary delegates
    messageInputBar.delegate = self
    messagesCollectionView.messagesDataSource = self
    messagesCollectionView.messagesLayoutDelegate = self
    messagesCollectionView.messagesDisplayDelegate = self
    
    // When keyboard opened, scroll down so same message is displayed as before
    maintainPositionOnKeyboardFrameChanged = true
    
    // Customize look of messageInputBar
    messageInputBar.inputTextView.tintColor = sendButtonColor
    messageInputBar.sendButton.setTitleColor(sendButtonColor, for: .normal)
    
    if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
        
        // do not display avatars
        layout.attributedTextMessageSizeCalculator.outgoingAvatarSize = .zero
        layout.attributedTextMessageSizeCalculator.incomingAvatarSize = .zero
        
        // for testing - makes bounds of view obvious
//        layout.collectionView?.backgroundColor = .red
    }
}
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // must be first responder in order for messageInputView to appear
        if !self.isFirstResponder {
            self.becomeFirstResponder()
        }
    }
  
  // MARK: - Helpers
  
    // "sends" message by saving it to the db
    private func save(_ message: Message) {
        reference?.addDocument(data: message.representation) { error in
            if let e = error {
                print("Error sending message: \(e.localizedDescription)")
                return
            }
            self.messagesCollectionView.scrollToBottom()
        }
    }
  
    // puts a message into the message container
    private func insertNewMessage(_ message: Message) {
        guard !messages.contains(message) else {
            print("message already in messages")
            return
        }

        messages.append(message)
        messages.sort()

        let isLatestMessage = messages.firstIndex(of: message) == (messages.count - 1)
        let shouldScrollToBottom = messagesCollectionView.isAtBottom && isLatestMessage

        messagesCollectionView.reloadData()

        if shouldScrollToBottom {
            DispatchQueue.main.async {
                self.messagesCollectionView.scrollToBottom(animated: true)
            }
        }
    }
  
    // handles updates from the database
    private func handleDocumentChange(_ change: DocumentChange) {
        guard let message = Message(document: change.document) else {
            print("message could not be created")
            print(change.document)
            return
        }

        switch change.type {
            case .added:
                insertNewMessage(message)

            default:
                break
            }
        }
    }

// MARK: - MessagesDisplayDelegate

extension ChatViewController: MessagesDisplayDelegate {
  
    // dictates the style of a message
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }
  
}

// MARK: - MessagesLayoutDelegate

extension ChatViewController: MessagesLayoutDelegate {
  
    // dictates the height of the cell top (sender name)
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 15
    }
  
}

// MARK: - MessagesDataSource

extension ChatViewController: MessagesDataSource {
    
    // represents the our user as a message sender
    func currentSender() -> SenderType {
        return FireFingersSender(senderId: user!.uid, displayName: user?.email ?? "Guest")
    }
    
    // each message is its own section
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
  
    // ordering of messages
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
  
    // the text to display above each message (sender name)
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(
          string: name,
          attributes: [
            .font: UIFont.preferredFont(forTextStyle: .caption1),
            .foregroundColor: UIColor(white: 0.3, alpha: 1)
          ]
        )
    }
  
}

// MARK: - MessageInputBarDelegate

extension ChatViewController: InputBarAccessoryViewDelegate {
  
    // initiates message send
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        print("registered send press with '\(text)'")
        let message = Message(user: user!, content: text)

        save(message)
        inputBar.inputTextView.text = ""
    }
  
}

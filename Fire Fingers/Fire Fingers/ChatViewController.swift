//
//  ChatViewController.swift
//  Fire Fingers
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
  
    let primaryColor = UIColor(red: 1 / 255, green: 93 / 255, blue: 48 / 255, alpha: 1)
    let incominMessageColor = UIColor(red: 230 / 255, green: 230 / 255, blue: 230 / 255, alpha: 1)
  
  private let db = Firestore.firestore()
  private var reference: CollectionReference?

  private var messages: [Message] = []
  private var messageListener: ListenerRegistration?
  
  let user: User?
  let lobby: Lobby?
  
  deinit {
    messageListener?.remove()
  }

  init(user: User, lobby: Lobby) {
    self.user = user
    self.lobby = lobby
    super.init(nibName: nil, bundle: nil)

    title = lobby.name
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    title = lobby!.name
    guard let id = lobby!.id else {
      navigationController?.popViewController(animated: true)
        print("failed to find lobby id")
      return
    }

    reference = db.collection(["lobbies", id, "thread"].joined(separator: "/"))
    
    messageListener = reference?.addSnapshotListener { querySnapshot, error in
      guard let snapshot = querySnapshot else {
        print("Error listening for lobby updates: \(error?.localizedDescription ?? "No error")")
        return
      }
      
      snapshot.documentChanges.forEach { change in
        self.handleDocumentChange(change)
      }
    }
    
    navigationItem.largeTitleDisplayMode = .never
    
    maintainPositionOnKeyboardFrameChanged = true
    messageInputBar.inputTextView.tintColor = primaryColor
    messageInputBar.sendButton.setTitleColor(primaryColor, for: .normal)
    
    messageInputBar.delegate = self
    messagesCollectionView.messagesDataSource = self
    messagesCollectionView.messagesLayoutDelegate = self
    messagesCollectionView.messagesDisplayDelegate = self
    
    
    messageInputBar.leftStackView.alignment = .center
    messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)
    messageInputBar.setStackViewItems([], forStack: .left, animated: false) // 3
    
    if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
        layout.attributedTextMessageSizeCalculator.outgoingAvatarSize = .zero
        layout.attributedTextMessageSizeCalculator.incomingAvatarSize = .zero
        layout.collectionView?.backgroundColor = .red
    }
}
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !self.isFirstResponder {
            self.becomeFirstResponder()
        }
    }
  
  // MARK: - Helpers
  
  private func save(_ message: Message) {
    reference?.addDocument(data: message.representation) { error in
      if let e = error {
        print("Error sending message: \(e.localizedDescription)")
        return
      }
      self.messagesCollectionView.scrollToBottom()
    }
  }
  
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
  
  func shouldDisplayHeader(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> Bool {
    return false
  }
  
  func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
    let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
    return .bubbleTail(corner, .curved)
  }
  
}

// MARK: - MessagesLayoutDelegate

extension ChatViewController: MessagesLayoutDelegate {
  
  func footerViewSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
    return CGSize(width: 0, height: 8)
  }
  
  func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
    
    return 15
  }
  
}

// MARK: - MessagesDataSource

extension ChatViewController: MessagesDataSource {
    func currentSender() -> SenderType {
        return FireFingersSender(senderId: user!.uid, displayName: user!.email!)
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        print("num messages \(messages.count)")
        return messages.count
    }
  
  func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
    return messages[indexPath.section]
  }
  
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
  
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        print("registered send press with '\(text)'")
    let message = Message(user: user!, content: text)

    save(message)
    inputBar.inputTextView.text = ""
  }
  
}

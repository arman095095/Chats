//
//  File.swift
//  
//
//  Created by Арман Чархчян on 10.04.2022.
//

import Foundation
import FirebaseFirestore
import NetworkServices
import UIKit

public protocol MessagingNetworkServiceProtocol {
    func send(message: MessageNetworkModelProtocol,
              completion: @escaping (Result<Void, Error>) -> Void)
    func initNewMessagesSocket(lastMessageDate: @escaping ((String) -> Date?),
                               accountID: String,
                               from id: String,
                               completion: @escaping (Result<[MessageNetworkModelProtocol], Error>) -> Void) -> SocketProtocol
    func initLookedMessagesSocket(accountID: String,
                                  from id: String,
                                  completion: @escaping (Result<Void, Error>) -> Void) -> SocketProtocol
    func sendLookedMessages(from id: String,
                            for friendID: String,
                            messageIDs: [String],
                            completion: @escaping (Result<Void, Error>) -> Void)
    func typingStatus(from id: String,
                      for friendID: String,
                      completion: @escaping (Bool) -> Void)
    func getMessages(from id: String,
                     friendID: String,
                     lastDate: Date?,
                     completion: @escaping (Result<[MessageNetworkModelProtocol], Error>) -> Void)
    func sendDidBeganTyping(from id: String,
                            friendID: String,
                            completion: @escaping (Result<Void, Error>) -> Void)
    func sendDidFinishTyping(from id: String,
                             friendID: String,
                             completion: @escaping (Result<Void, Error>) -> Void)
    func initTypingStatusSocket(from id: String,
                                friendID: String,
                                completion: @escaping (Bool?) -> Void) -> SocketProtocol
    func removeChat(from id: String,
                    for friendID: String,
                    completion: @escaping () -> ())
}

public final class MessagingNetworkService {
    
    private let networkServiceRef: Firestore
    
    private var usersRef: CollectionReference {
        return networkServiceRef.collection(URLComponents.Paths.users.rawValue)
    }
    
    public init(networkService: Firestore) {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = false
        networkService.settings = settings
        self.networkServiceRef = networkService
    }
}

extension MessagingNetworkService: MessagingNetworkServiceProtocol {
    
    public func getMessages(from id: String,
                            friendID: String,
                            lastDate: Date?,
                            completion: @escaping (Result<[MessageNetworkModelProtocol], Error>) -> Void) {
        let ref = usersRef
            .document(id)
            .collection(URLComponents.Paths.friendIDs.rawValue)
            .document(friendID)
            .collection(URLComponents.Paths.messages.rawValue)
        
        let handler: ((QuerySnapshot?, Error?) -> ()) = { querySnapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            var messages = [MessageNetworkModelProtocol]()
            querySnapshot?.documents.forEach {
                guard let message = MessageNetworkModel(queryDocumentSnapshot: $0) else { return }
                guard message.date != lastDate else { return }
                messages.append(message)
            }
            completion(.success(messages))
        }
        
        if let lastDate = lastDate {
            ref.whereField(URLComponents.Parameters.date.rawValue, isGreaterThan: lastDate).getDocuments(completion: handler)
        } else {
            ref.getDocuments(completion: handler)
        }
    }
    
    public func removeChat(from id: String, for friendID: String, completion: @escaping () -> ()) {
        let myRefMessages = usersRef
            .document(id)
            .collection(URLComponents.Paths.friendIDs.rawValue)
            .document(friendID)
            .collection(URLComponents.Paths.messages.rawValue)
        myRefMessages.getDocuments { querySnapshot, error in
            querySnapshot?.documents.forEach {
                myRefMessages.document($0.documentID).delete()
            }
            
        }
        let friendRefMessages = usersRef
            .document(friendID)
            .collection(URLComponents.Paths.friendIDs.rawValue)
            .document(id)
            .collection(URLComponents.Paths.messages.rawValue)
        friendRefMessages.getDocuments { querySnapshot, error in
            querySnapshot?.documents.forEach {
                friendRefMessages.document($0.documentID).delete()
            }
            
        }
        let myRefNotLooked = usersRef
            .document(id)
            .collection(URLComponents.Paths.friendIDs.rawValue)
            .document(friendID)
            .collection(URLComponents.Paths.lookedMessages.rawValue)
        myRefNotLooked.getDocuments { querySnapshot, error in
            querySnapshot?.documents.forEach {
                myRefNotLooked.document($0.documentID).delete()
            }
            
        }
        let friendRefNotLooked = usersRef
            .document(friendID)
            .collection(URLComponents.Paths.friendIDs.rawValue)
            .document(id)
            .collection(URLComponents.Paths.lookedMessages.rawValue)
        friendRefNotLooked.getDocuments { querySnapshot, error in
            querySnapshot?.documents.forEach {
                friendRefNotLooked.document($0.documentID).delete()
            }
            
        }
    }
    
    public func send(message: MessageNetworkModelProtocol, completion: @escaping (Result<Void, Error>) -> Void) {
        if !InternetConnectionManager.isConnectedToNetwork() {
            completion(.failure(ConnectionError.noInternet))
        }
        usersRef
            .document(message.senderID)
            .collection(URLComponents.Paths.friendIDs.rawValue)
            .document(message.adressID)
            .collection(URLComponents.Paths.messages.rawValue)
            .document(message.id)
            .setData(message.convertModelToDictionary()) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                message.status = .incomingNew
                self.usersRef
                    .document(message.adressID)
                    .collection(URLComponents.Paths.friendIDs.rawValue)
                    .document(message.senderID)
                    .collection(URLComponents.Paths.messages.rawValue)
                    .document(message.id)
                    .setData(message.convertModelToDictionary()) { error in
                        if let error = error {
                            completion(.failure(error))
                            return
                        }
                        completion(.success(()))
                    }
            }
    }
    
    public func initNewMessagesSocket(lastMessageDate: @escaping ((String) -> Date?),
                                      accountID: String,
                                      from id: String,
                                      completion: @escaping (Result<[MessageNetworkModelProtocol], Error>) -> Void) -> SocketProtocol {
        let ref = usersRef
            .document(accountID)
            .collection(URLComponents.Paths.friendIDs.rawValue)
            .document(id)
            .collection(URLComponents.Paths.messages.rawValue)
        let handler: ((QuerySnapshot?, Error?) -> ()) = { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let querySnapshot = querySnapshot, !querySnapshot.isEmpty else { return }
            var newMessages = [MessageNetworkModelProtocol]()
            querySnapshot.documentChanges.forEach { change in
                guard case .added = change.type else { return }
                guard let message = MessageNetworkModel(queryDocumentSnapshot: change.document) else { return }
                guard message.date != lastMessageDate(id) else { return }
                newMessages.append(message)
            }
            completion(.success(newMessages))
        }
        var listener: ListenerRegistration
        if let lastMessageDate = lastMessageDate(id) {
            let query = ref.whereField(URLComponents.Parameters.date.rawValue, isGreaterThan: lastMessageDate)
            listener = query.addSnapshotListener(handler)
        } else {
            listener = ref.addSnapshotListener(handler)
        }
        return FirestoreSocketAdapter(adaptee: listener)
    }
    
    public func sendLookedMessages(from id: String,
                                   for friendID: String,
                                   messageIDs: [String],
                                   completion: @escaping (Result<Void, Error>) -> Void) {
        if !InternetConnectionManager.isConnectedToNetwork() {
            completion(.failure(ConnectionError.noInternet))
        }
        messageIDs.forEach {
            usersRef
                .document(friendID)
                .collection(URLComponents.Paths.friendIDs.rawValue)
                .document(id)
                .collection(URLComponents.Paths.messages.rawValue)
                .document($0)
                .updateData([URLComponents.Parameters.status.rawValue: MessageStatus.looked.rawValue])
            usersRef
                .document(id)
                .collection(URLComponents.Paths.friendIDs.rawValue)
                .document(friendID)
                .collection(URLComponents.Paths.messages.rawValue)
                .document($0)
                .updateData([URLComponents.Parameters.status.rawValue: MessageStatus.incoming.rawValue])
        }
        usersRef
            .document(friendID)
            .collection(URLComponents.Paths.friendIDs.rawValue)
            .document(id)
            .collection(URLComponents.Paths.lookedMessages.rawValue)
            .addDocument(data: [URLComponents.Parameters.id.rawValue: UUID().uuidString])
    }
    
    public func initLookedMessagesSocket(accountID: String,
                                         from id: String,
                                         completion: @escaping (Result<Void, Error>) -> Void) -> SocketProtocol {
        let ref = usersRef
            .document(accountID)
            .collection(URLComponents.Paths.friendIDs.rawValue)
            .document(id)
            .collection(URLComponents.Paths.lookedMessages.rawValue)
        let listener = ref.addSnapshotListener { query, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let querySnapshot = query else { return }
                querySnapshot.documentChanges.forEach { change in
                    guard case .added = change.type else { return }
                    ref.document(change.document.documentID).delete()
                    completion(.success(()))
                }
            }
        return FirestoreSocketAdapter(adaptee: listener)
    }
    
    public func typingStatus(from id: String, for friendID: String, completion: @escaping (Bool) -> Void) {
        usersRef
            .document(id)
            .collection(URLComponents.Paths.friendIDs.rawValue)
            .document(friendID)
            .collection(URLComponents.Paths.typing.rawValue)
            .document(friendID)
            .getDocument { (documentSnapshot, error) in
                if let _ = error {
                    completion(false)
                    return
                }
                guard let doc = documentSnapshot else {
                    completion(false)
                    return
                }
                guard let _ = doc.data()?[URLComponents.Parameters.id.rawValue] as? String else {
                    completion(false)
                    return
                }
                completion(true)
            }
    }
    
    public func sendDidBeganTyping(from id: String, friendID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        if !InternetConnectionManager.isConnectedToNetwork() {
            completion(.failure(ConnectionError.noInternet))
        }
        usersRef
            .document(friendID)
            .collection(URLComponents.Paths.friendIDs.rawValue)
            .document(id)
            .collection(URLComponents.Paths.typing.rawValue)
            .document(id)
            .setData([URLComponents.Parameters.id.rawValue: id]) { (error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success(()))
            }
    }
    
    public func sendDidFinishTyping(from id: String, friendID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        if !InternetConnectionManager.isConnectedToNetwork() {
            completion(.failure(ConnectionError.noInternet))
        }
        usersRef
            .document(friendID)
            .collection(URLComponents.Paths.friendIDs.rawValue)
            .document(id)
            .collection(URLComponents.Paths.typing.rawValue)
            .document(id)
            .delete { (error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success(()))
            }
    }
    
    public func initTypingStatusSocket(from id: String, friendID: String ,completion: @escaping (Bool?) -> Void) -> SocketProtocol {
        let ref = usersRef
            .document(id)
            .collection(URLComponents.Paths.friendIDs.rawValue)
            .document(friendID)
            .collection(URLComponents.Paths.typing.rawValue)
        
        let listener = ref.addSnapshotListener { (querySnapshot, error) in
            if let _ = error {
                completion(nil)
                return
            }
            guard let querySnapshot = querySnapshot,
                  let first = querySnapshot.documentChanges.first else {
                completion(nil)
                return
            }
            switch first.type {
            case .added:
                completion(true)
            case .removed:
                completion(false)
            default:
                completion(nil)
            }
        }
        return FirestoreSocketAdapter(adaptee: listener)
    }
}

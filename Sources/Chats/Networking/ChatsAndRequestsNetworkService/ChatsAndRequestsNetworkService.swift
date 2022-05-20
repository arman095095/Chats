//
//  File.swift
//  
//
//  Created by Арман Чархчян on 20.05.2022.
//

import Foundation
import NetworkServices
import FirebaseFirestore

public protocol ChatsAndRequestsNetworkServiceProtocol {
    func initRequestsSocket(userID: String,
                                   completion: @escaping (Result<(add: [String],removed: [String]), Error>) -> Void) -> SocketProtocol
    func initSendedRequestsSocket(userID: String,
                                         completion: @escaping (Result<(add: [String], removed: [String]), Error>) -> Void) -> SocketProtocol
    func initFriendsSocket(userID: String,
                           completion: @escaping (Result<(add: [String],removed: [String]), Error>) -> Void) -> SocketProtocol
    func removeFriend(with friendID: String, from id: String, completion: @escaping (Result<Void, Error>) -> ())
    func friendIDs(userID: String, completion: @escaping (Result<[String], Error>) -> ())
    func waitingIDs(userID: String, completion: @escaping (Result<[String], Error>) -> ())
    func requestIDs(userID: String, completion: @escaping (Result<[String], Error>) -> ())
}

final class ChatsAndRequestsNetworkService {
    private let networkServiceRef: Firestore

    private var usersRef: CollectionReference {
        return networkServiceRef.collection(URLComponents.Paths.users.rawValue)
    }
    
    init(networkService: Firestore) {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = false
        networkService.settings = settings
        self.networkServiceRef = networkService
    }
}

extension ChatsAndRequestsNetworkService: ChatsAndRequestsNetworkServiceProtocol {
    public func initRequestsSocket(userID: String,
                                   completion: @escaping (Result<(add: [String],removed: [String]), Error>) -> Void) -> SocketProtocol {
        let listener =  usersRef.document(userID).collection(URLComponents.Paths.waitingUsers.rawValue).addSnapshotListener { querySnapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let querySnapshot = querySnapshot else { return }
            var newRequests = [String]()
            var removedRequest = [String]()
            querySnapshot.documentChanges.forEach {
                switch $0.type {
                case .added:
                    newRequests.append($0.document.documentID)
                case .removed:
                    removedRequest.append($0.document.documentID)
                default:
                    break
                }
            }
            completion(.success((add: newRequests, removed: removedRequest)))
        }
        return FirestoreSocketAdapter(adaptee: listener)
    }
    
    public func initSendedRequestsSocket(userID: String,
                                         completion: @escaping (Result<(add: [String], removed: [String]), Error>) -> Void) -> SocketProtocol {
        let listener =  usersRef.document(userID).collection(URLComponents.Paths.sendedRequests.rawValue).addSnapshotListener { querySnapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let querySnapshot = querySnapshot else { return }
            var newRequests = [String]()
            var removedRequest = [String]()
            querySnapshot.documentChanges.forEach {
                switch $0.type {
                case .added:
                    newRequests.append($0.document.documentID)
                case .removed:
                    removedRequest.append($0.document.documentID)
                default:
                    break
                }
            }
            completion(.success((add: newRequests, removed: removedRequest)))
        }
        return FirestoreSocketAdapter(adaptee: listener)
    }
    
    public func initFriendsSocket(userID: String,
                                  completion: @escaping (Result<(add: [String],removed: [String]), Error>) -> Void) -> SocketProtocol {
        let listener =  usersRef.document(userID).collection(URLComponents.Paths.friendIDs.rawValue).addSnapshotListener { querySnapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let querySnapshot = querySnapshot else { return }
            var newFriends = [String]()
            var removedFriends = [String]()
            querySnapshot.documentChanges.forEach {
                switch $0.type {
                case .added:
                    newFriends.append($0.document.documentID)
                case .removed:
                    removedFriends.append($0.document.documentID)
                default:
                    break
                }
            }
            completion(.success((add: newFriends, removed: removedFriends)))
        }
        return FirestoreSocketAdapter(adaptee: listener)
    }
    
    public func removeFriend(with friendID: String, from id: String, completion: @escaping (Result<Void, Error>) -> ()) {
        usersRef.document(id).collection(URLComponents.Paths.friendIDs.rawValue).document(friendID).delete { [weak self] error in
            if let error = error {
                completion(.failure(error))
                return
            }
            self?.usersRef.document(friendID).collection(URLComponents.Paths.friendIDs.rawValue).document(id).delete { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success(()))
            }
        }
    }
    
    public func friendIDs(userID: String, completion: @escaping (Result<[String], Error>) -> ()) {
        usersRef.document(userID).collection(URLComponents.Paths.friendIDs.rawValue).getDocuments { query, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let query = query else { return }
            completion(.success(query.documents.map { $0.documentID }))
        }
    }
    
    public func waitingIDs(userID: String, completion: @escaping (Result<[String], Error>) -> ()) {
        usersRef.document(userID).collection(URLComponents.Paths.waitingUsers.rawValue).getDocuments { query, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let query = query else { return }
            completion(.success(query.documents.map { $0.documentID }))
        }
    }
    
    public func requestIDs(userID: String, completion: @escaping (Result<[String], Error>) -> ()) {
        usersRef.document(userID).collection(URLComponents.Paths.sendedRequests.rawValue).getDocuments { query, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let query = query else { return }
            completion(.success(query.documents.map { $0.documentID }))
        }
    }
}

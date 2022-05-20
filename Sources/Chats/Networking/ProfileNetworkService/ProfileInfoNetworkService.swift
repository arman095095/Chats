//
//  File.swift
//  
//
//  Created by Арман Чархчян on 20.05.2022.
//

import Foundation
import NetworkServices
import FirebaseFirestore
import ModelInterfaces

protocol ProfileInfoNetworkServiceProtocol {
    func getProfileInfo(userID: String, completion: @escaping (Result<ProfileNetworkModelProtocol,Error>) -> ())
    func initProfileSocket(userID: String, completion: @escaping (Result<ProfileNetworkModelProtocol, Error>) -> Void) -> SocketProtocol
}

final class ProfileInfoNetworkService {
    
    private let networkServiceRef: Firestore
    
    private var usersRef: CollectionReference {
        return networkServiceRef.collection(ProfileURLComponents.Paths.users.rawValue)
    }
    
    init(networkService: Firestore) {
        self.networkServiceRef = networkService
    }
}

extension ProfileInfoNetworkService: ProfileInfoNetworkServiceProtocol {
    
    func getProfileInfo(userID: String, completion: @escaping (Result<ProfileNetworkModelProtocol,Error>) -> ()) {
        usersRef.document(userID).getDocument { [weak self] (documentSnapshot, error) in
            if let error = error  {
                completion(.failure(error))
                return
            }
            if let dict = documentSnapshot?.data() {
                if var muser = ProfileNetworkModel(dict: dict) {
                    self?.getProfilePostsCount(userID: userID) { (result) in
                        switch result {
                        case .success(let count):
                            muser.postsCount = count
                            completion(.success(muser))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                } else {
                    completion(.failure(GetUserInfoError.convertData))
                }
            } else {
                completion(.failure(GetUserInfoError.getData))
            }
        }
    }
    
    func initProfileSocket(userID: String, completion: @escaping (Result<ProfileNetworkModelProtocol, Error>) -> Void) -> SocketProtocol {
        let listener = usersRef.document(userID).addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let snapshot = snapshot,
                  let data = snapshot.data(),
                  let profile = ProfileNetworkModel(dict: data) else { return }
            completion(.success(profile))
        }
        return FirestoreSocketAdapter(adaptee: listener)
    }
}

private extension ProfileInfoNetworkService {
    func getProfilePostsCount(userID: String, completion: @escaping (Result<Int,Error>) -> ()) {
        usersRef.document(userID).collection(ProfileURLComponents.Paths.posts.rawValue).getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let querySnapshot = querySnapshot else { return }
            let count = querySnapshot.count
            completion(.success(count))
        }
    }
}

//
//  File.swift
//  
//
//  Created by Арман Чархчян on 20.05.2022.
//

import Foundation
import FirebaseStorage
import NetworkServices

public protocol ChatsRemoteStorageServiceProtocol {
    func uploadChat(audio: Data, completion: @escaping (Result<String, Error>) -> Void)
    func uploadChat(image: Data, completion: @escaping (Result<String, Error>) -> Void)
    func download(url: URL, completion: @escaping (Result<Data, Error>) -> Void)
    func delete(from url: URL)
}

final class ChatsRemoteStorageService {

    private let storage: Storage
    
    private var chatsImagesRef: StorageReference {
        storage.reference().child(StorageURLComponents.Paths.chats.rawValue)
    }
    
    private var audioRef: StorageReference {
        storage.reference().child(StorageURLComponents.Paths.audio.rawValue)
    }
    
    init(storage: Storage) {
        self.storage = storage
    }
}

extension ChatsRemoteStorageService: ChatsRemoteStorageServiceProtocol {

    public func uploadChat(audio: Data, completion: @escaping (Result<String, Error>) -> Void) {
        let metadata = StorageMetadata()
        metadata.contentType = StorageURLComponents.Parameters.audioM4A.rawValue
        let audioName = [UUID().uuidString,Date().description, StorageURLComponents.Parameters.m4a.rawValue].joined()
        audioRef.child(audioName).putData(audio, metadata: metadata) { [weak self] (metadata, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            self?.audioRef.child(audioName).downloadURL { (url, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let downloadURL = url else { return }
                completion(.success(downloadURL.absoluteString))
            }
        }
    }
    
    public func uploadChat(image: Data, completion: @escaping (Result<String, Error>) -> Void) {
        let metadata = StorageMetadata()
        metadata.contentType = StorageURLComponents.Parameters.imageJpeg.rawValue
        let photoName = [UUID().uuidString,Date().description].joined()
        
        chatsImagesRef.child(photoName).putData(image, metadata: metadata) { (metadata, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            self.chatsImagesRef.child(photoName).downloadURL { (url, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let downloadURL = url else { return }
                completion(.success(downloadURL.absoluteString))
            }
        }
    }
    
    public func download(url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        let ref = storage.reference(forURL: url.absoluteString)
        let megaByte = Int64(1*1024*1024)
        ref.getData(maxSize: megaByte) { [weak self] (data, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else { return }
            self?.delete(from: url)
            completion(.success(data))
        }
    }
    
    public func delete(from url: URL) {
        let ref = storage.reference(forURL: url.absoluteString)
        ref.delete { _ in }
    }
}

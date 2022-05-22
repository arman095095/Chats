//
//  MessangerChatInteractor.swift
//  
//
//  Created by Арман Чархчян on 12.05.2022.
//  Copyright (c) 2022 ___ORGANIZATIONNAME___. All rights reserved.
//

import UIKit
import MessageKit
import Managers
import ModelInterfaces

protocol MessangerChatInteractorInput: AnyObject {
    func configureAudioCell(cell: AudioMessageCell, message: MessageType)
    func playAudioMessage(message: MessageType, cell: AudioMessageCell)
    func beginRecord()
    func cancelRecord()
    func finishRecord()
    func sendAudioMessage(url: String, duration: Float)
    func sendTextMessage(content: String)
    func sendPhotoMessage(data: Data, ratio: Double)
    func sendDidBeganTyping()
    func sendDidFinishTyping()
    func readNewMessages()
    func startObserve()
    func stopObserving()
}

protocol MessangerChatInteractorOutput: AnyObject {
    var chatID: String { get }
    func successAudioRecorded(url: String, duration: Float)
    func successRecievedNewMessages(messagesCount: Int)
    func successCreatedMessage()
    func successLookedMessages()
    func friendIsTyping()
    func friendFinishTyping()
}

final class MessangerChatInteractor {
    
    weak var output: MessangerChatInteractorOutput?
    private let messagingManager: MessagingSendManagerProtocol
    private let chatManager: MessagingRecieveManagerProtocol
    private let audioRecorder: AudioMessageRecorderProtocol
    private let audioPlayer: AudioMessagePlayerProtocol
    
    init(messagingManager: MessagingSendManagerProtocol,
         chatManager: MessagingRecieveManagerProtocol,
         audioRecorder: AudioMessageRecorderProtocol,
         audioPlayer: AudioMessagePlayerProtocol) {
        self.messagingManager = messagingManager
        self.audioRecorder = audioRecorder
        self.audioPlayer = audioPlayer
        self.chatManager = chatManager
    }
}

extension MessangerChatInteractor: MessagingRecieveDelegate {
    func newMessagesRecieved(friendID: String, messages: [MessageModelProtocol]) {
        guard friendID == output?.chatID, !messages.isEmpty else { return }
        output?.successRecievedNewMessages(messagesCount: messages.count)
    }
    
    func messagesLooked(friendID: String) {
        guard friendID == output?.chatID else { return }
        output?.successLookedMessages()
    }
    
    func typing(friendID: String, _ value: Bool) {
        guard friendID == output?.chatID else { return }
        value ? output?.friendIsTyping() : output?.friendFinishTyping()
    }
}

extension MessangerChatInteractor: MessangerChatInteractorInput {

    func readNewMessages() {
        messagingManager.readNewMessages()
    }
    
    func sendDidBeganTyping() {
        messagingManager.sendDidBeganTyping()
    }
    
    func sendDidFinishTyping() {
        messagingManager.sendDidFinishTyping()
    }
    
    func startObserve() {
        chatManager.addDelegate(self)
    }
    
    func stopObserving() {
        chatManager.removeDelegate(self)
    }

    func sendAudioMessage(url: String, duration: Float) {
        messagingManager.sendAudioMessage(url, duration: duration) { [weak self] result in
            switch result {
            case .success:
                self?.output?.successCreatedMessage()
            case .failure:
                break
            }
        }
    }
    
    func sendTextMessage(content: String) {
        messagingManager.sendTextMessage(content) { [weak self] result in
            switch result {
            case .success:
                self?.output?.successCreatedMessage()
            case .failure:
                break
            }
        }
    }
    
    func sendPhotoMessage(data: Data, ratio: Double) {
        messagingManager.sendPhotoMessage(data, ratio: ratio) { [weak self] result in
            switch result {
            case .success:
                self?.output?.successCreatedMessage()
            case .failure:
                break
            }
        }
    }

    func configureAudioCell(cell: AudioMessageCell, message: MessageType) {
        audioPlayer.configureAudioCell(cell, message: message)
    }

    func playAudioMessage(message: MessageType, cell: AudioMessageCell) {
        guard audioPlayer.state != .stopped else {
            audioPlayer.playSound(for: message, in: cell)
            return
        }
        if audioPlayer.playingMessage?.messageId == message.messageId {
            if audioPlayer.state == .playing {
                audioPlayer.pauseSound(for: message, in: cell)
            } else {
                audioPlayer.resumeSound()
            }
        } else {
            audioPlayer.stopAnyOngoingPlaying()
            audioPlayer.playSound(for: message, in: cell)
        }
    }
    
    func beginRecord() {
        audioPlayer.stopAnyOngoingPlaying()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.audioRecorder.beginRecord()
        }
    }

    func cancelRecord() {
        audioRecorder.cancelRecord()
    }

    func finishRecord() {
        guard let audioInfo = audioRecorder.stopRecord() else { return }
        output?.successAudioRecorded(url: audioInfo.0, duration: audioInfo.1)
    }

}

//
//  File.swift
//  
//
//  Created by Арман Чархчян on 14.05.2022.
//

import UIKit
import AVFoundation
import MessageKit
import NetworkServices
import Services
import ModelInterfaces

/// The `PlayerState` indicates the current audio controller state
enum PlayerState {
    case playing
    case pause
    case stopped
}

protocol AudioMessagePlayerProtocol: AnyObject {
    var state: PlayerState { get }
    var playingMessage: MessageType? { get }
    func configureAudioCell(_ cell: AudioMessageCell, message: MessageType)
    func playSound(for message: MessageType, in audioCell: AudioMessageCell)
    func pauseSound(for message: MessageType, in audioCell: AudioMessageCell)
    func stopAnyOngoingPlaying()
    func resumeSound()
}

final class AudioMessagePlayer: NSObject {
    
    private var audioPlayer: AVAudioPlayer?
    private weak var playingCell: AudioMessageCell?
    var playingMessage: MessageType?
    private(set) var state: PlayerState = .stopped
    private weak var messageCollectionView: MessagesCollectionView?
    private let remoteStorageService: ChatsRemoteStorageServiceProtocol
    private let cacheService: MessagesCacheServiceProtocol
    
    internal var progressTimer: Timer?
    
    // MARK: - Init Methods
    public init(messageCollectionView: MessagesCollectionView,
                remoteStorageService: ChatsRemoteStorageServiceProtocol,
                cacheService: MessagesCacheServiceProtocol) {
        self.messageCollectionView = messageCollectionView
        self.remoteStorageService = remoteStorageService
        self.cacheService = cacheService
        super.init()
    }
    
    deinit {
        progressTimer?.invalidate()
        progressTimer = nil
    }
}
extension AudioMessagePlayer: AudioMessagePlayerProtocol {
    
    func configureAudioCell(_ cell: AudioMessageCell, message: MessageType) {
        if playingMessage?.messageId == message.messageId, let collectionView = messageCollectionView, let player = audioPlayer {
            playingCell = cell
            cell.progressView.progress = (player.duration == 0) ? 0 : Float(player.currentTime/player.duration)
            cell.playButton.isSelected = (player.isPlaying == true) ? true : false
            guard let displayDelegate = collectionView.messagesDisplayDelegate else {
                fatalError("MessagesDisplayDelegate has not been set.")
            }
            cell.durationLabel.text = displayDelegate.audioProgressTextFormat(Float(player.currentTime), for: cell, in: collectionView)
        }
    }
    
    func playSound(for message: MessageType, in audioCell: AudioMessageCell) {
        switch message.kind {
        case .custom(let kind):
            guard let type = kind as? MessageKind else { return }
            switch type {
            case .audio(let item):
                playingCell = audioCell
                playingMessage = message
                let url = FileManager.getDocumentsDirectory().appendingPathComponent(item.url.absoluteString)
                guard let player = try? AVAudioPlayer(contentsOf: url) else {
                    download(url: item.url, for: message, in: audioCell)
                    return
                }
                play(player: player, audioCell: audioCell, message: message)
            default:
                break
            }
        default:
            break
        }
    }
    
    func pauseSound(for message: MessageType, in audioCell: AudioMessageCell) {
        audioPlayer?.pause()
        state = .pause
        audioCell.playButton.isSelected = false
        progressTimer?.invalidate()
        if let cell = playingCell {
            cell.delegate?.didPauseAudio(in: cell)
        }
    }
    
    func stopAnyOngoingPlaying() {
        guard let player = audioPlayer, let collectionView = messageCollectionView else { return }
        player.stop()
        state = .stopped
        if let cell = playingCell {
            cell.progressView.progress = 0.0
            cell.playButton.isSelected = false
            guard let displayDelegate = collectionView.messagesDisplayDelegate else {
                fatalError("MessagesDisplayDelegate has not been set.")
            }
            cell.durationLabel.text = displayDelegate.audioProgressTextFormat(Float(player.duration), for: cell, in: collectionView)
            cell.delegate?.didStopAudio(in: cell)
        }
        progressTimer?.invalidate()
        progressTimer = nil
        audioPlayer = nil
        playingMessage = nil
        playingCell = nil
    }
    
    func resumeSound() {
        guard let player = audioPlayer, let cell = playingCell else {
            stopAnyOngoingPlaying()
            return
        }
        player.prepareToPlay()
        player.play()
        state = .playing
        startProgressTimer()
        cell.playButton.isSelected = true // show pause button on audio cell
        cell.delegate?.didStartAudio(in: cell)
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioMessagePlayer: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopAnyOngoingPlaying()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        stopAnyOngoingPlaying()
    }
}

private extension AudioMessagePlayer {
    func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
        let timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(AudioMessagePlayer.didFireProgressTimer(_:)), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        self.progressTimer = timer
    }
    
    @objc func didFireProgressTimer(_ timer: Timer) {
        guard let player = audioPlayer,
              let collectionView = messageCollectionView,
              let cell = playingCell else {
            return
        }
        if let playingCellIndexPath = collectionView.indexPath(for: cell) {
            let currentMessage = collectionView.messagesDataSource?.messageForItem(at: playingCellIndexPath, in: collectionView)
            if currentMessage != nil && currentMessage?.messageId == playingMessage?.messageId {
                cell.progressView.progress = (player.duration == 0) ? 0 : Float(player.currentTime/player.duration)
                guard let displayDelegate = collectionView.messagesDisplayDelegate else {
                    fatalError("MessagesDisplayDelegate has not been set.")
                }
                cell.durationLabel.text = displayDelegate.audioProgressTextFormat(Float(player.duration - player.currentTime), for: cell, in: collectionView)
            } else {
                stopAnyOngoingPlaying()
            }
        }
    }
    
    func download(url: URL, for message: MessageType, in audioCell: AudioMessageCell) {
        guard let customAudioCell = audioCell as? AudioMessageCellCustom else { return }
        customAudioCell.activityIndicator.isHidden = false
        customAudioCell.activityIndicator.startLoading()
        remoteStorageService.download(url: url) { [weak self] (result) in
            switch result {
            case .success(let data):
                let name = "\(UUID().uuidString).m4a"
                let newURL = FileManager.getDocumentsDirectory().appendingPathComponent(name)
                guard let _ = try? data.write(to: newURL) else { return }
                if let messageModel = message as? MessageModelProtocol {
                    guard case .audio(url: _, duration: let duration) = messageModel.type else { return }
                    messageModel.type = .audio(url: name, duration: duration)
                    self?.cacheService.update(messageModel)
                }
                guard let player = try? AVAudioPlayer(contentsOf: newURL) else { return }
                self?.play(player: player, audioCell: audioCell, message: message)
                customAudioCell.activityIndicator.completeLoading(success: true)
                customAudioCell.activityIndicator.isHidden = true
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    func play(player: AVAudioPlayer, audioCell: AudioMessageCell, message: MessageType) {
        audioPlayer = player
        audioPlayer?.prepareToPlay()
        audioPlayer?.delegate = self
        audioPlayer?.play()
        state = .playing
        audioCell.playButton.isSelected = true  // show pause button on audio cell
        startProgressTimer()
        audioCell.delegate?.didStartAudio(in: audioCell)
    }
}

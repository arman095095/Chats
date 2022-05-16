//
//  File.swift
//  
//
//  Created by Арман Чархчян on 13.05.2022.
//

import UIKit
import AVFoundation

protocol AudioMessageRecorderProtocol {
    func beginRecord()
    func stopRecord() -> (String,Float)?
    func cancelRecord()
}

final class AudioMessageRecorder: NSObject, AVAudioPlayerDelegate, AudioMessageRecorderProtocol {

    //Variables
    private var audioRecorder: AVAudioRecorder!
    private var isAudioRecordingGranted: Bool!
    private var name: String?

    private func checkAllowed() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case AVAudioSession.RecordPermission.granted:
            isAudioRecordingGranted = true
            break
        case AVAudioSession.RecordPermission.denied:
            isAudioRecordingGranted = false
            break
        case AVAudioSession.RecordPermission.undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.isAudioRecordingGranted = true
                    } else {
                        self.isAudioRecordingGranted = false
                    }
                }
            }
            break
        default:
            break
        }
    }
    
    override init() {
        super.init()
        checkAllowed()
    }
    
    //MARK:- StartRecord
    func beginRecord() {

        if isAudioRecordingGranted {
            //Create the session.
            let session = AVAudioSession.sharedInstance()

            do {
                //Configure the session for recording and playback.
                try session.setCategory(AVAudioSession.Category.playAndRecord, options: .defaultToSpeaker)
                try session.setActive(true)
                //Set up a high-quality recording session.
                let settings = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 2,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]
                //Create audio file name URL
                let name = "\(UUID().uuidString).m4a"
                self.name = name
                let audioFilename = FileManager.getDocumentsDirectory().appendingPathComponent(name)
                //Create the audio recording, and assign ourselves as the delegate
                audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
                audioRecorder.delegate = self
                audioRecorder.isMeteringEnabled = true
                audioRecorder.record()
            }
            catch let error {
                print("Error for start audio recording: \(error.localizedDescription)")
            }
        }
    }
    
    func stopRecord() -> (String,Float)? {
        return finishAudioRecording(success: true)
    }
    
    func cancelRecord() {
        let _ = finishAudioRecording(success: false)
    }
    
    private func finishAudioRecording(success: Bool) -> (String,Float)? {
        audioRecorder.stop()
        if success {
            guard let player = try? AVAudioPlayer(contentsOf: audioRecorder.url) else { return nil }
            let duration = player.duration
            guard let url = name else { return nil }
            name = nil
            audioRecorder = nil
            return (url,Float(duration))
        }
        else {
            guard let name = name else { return nil }
            try? FileManager.default.removeItem(at: FileManager.getDocumentsDirectory().appendingPathComponent(name))
            self.name = nil
            audioRecorder = nil
            return nil
        }
    }

}

//MARK:- Audio recoder delegate methods
extension AudioMessageRecorder: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            let _ = finishAudioRecording(success: false)
        }
    }
}

extension FileManager {
    static func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

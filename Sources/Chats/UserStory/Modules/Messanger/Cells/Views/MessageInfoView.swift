//
//  File.swift
//  
//
//  Created by Арман Чархчян on 13.05.2022.
//

import UIKit
import DesignSystem

enum StatusInfo {
    case waiting
    case sended
    case looked
    case error
    
    var imageName: String {
        switch self {
        case .waiting:
            return "wait"
        case .sended:
            return "sended1"
        case .looked:
            return "sended2"
        case .error:
            return "wait"
        }
    }
}

final class MessageInfoView: UIView {
    
    let dateLabel = UILabel()
    let sendStatusImageView = UIImageView()
    
    enum InfoType {
        
        enum MessageType {
            case audio
            case photo
            case text
        }
        
        case sender(MessageType)
        case recieved(MessageType)
    }
    
    var status: StatusInfo? {
        didSet {
            switch status {
            case .none:
                removeAnimationFromSendStatusImage()
            case .some(let stat):
                sendStatusImageView.image = UIImage(named: stat.imageName, in: Bundle.module, with: nil)
                switch stat {
                case .waiting:
                    addAnimationToSendStatusImage()
                default:
                    removeAnimationFromSendStatusImage()
                }
            }
        }
    }
    
    init(type: InfoType) {
        super.init(frame: .zero)
        switch type {
        case .sender(let messageType):
            switch messageType {
            case .audio:
                setupSendedTextViews()
            case .photo:
                setupSendedPhotoViews()
            case .text:
                setupSendedTextViews()
            }
        case .recieved(let messageType):
            switch messageType {
            case .audio:
                setupRecievedTextViews()
            case .photo:
                setupRecievedPhotoViews()
            case .text:
                setupRecievedTextViews()
            }
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func removeAnimationFromSendStatusImage() {
        sendStatusImageView.layer.removeAllAnimations()
    }
}

private extension MessageInfoView {
    
    func addAnimationToSendStatusImage() {
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.duration = 2.0
        animation.fromValue = 0.0
        animation.toValue = 2 * Double.pi
        animation.repeatCount = Float.infinity
        sendStatusImageView.layer.add(animation, forKey: CustomActivityIndicator.dhRingRotationAnimationKey)
    }
    
    func setupRecievedPhotoViews() {
        self.addSubview(dateLabel)
        backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5)
        layer.cornerRadius = 7
        layer.masksToBounds = true
        dateLabel.textColor = .white
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.textAlignment = .center
        dateLabel.font = UIFont.systemFont(ofSize: 10,weight: .light)
        dateLabel.widthAnchor.constraint(equalToConstant: 30).isActive = true
        dateLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        dateLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    }
    
    func setupSendedPhotoViews() {
        addSubview(dateLabel)
        addSubview(sendStatusImageView)
        backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5)
        dateLabel.textColor = .white
        dateLabel.textAlignment = .center
        layer.cornerRadius = 7
        layer.masksToBounds = true
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        sendStatusImageView.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.textAlignment = .left
        dateLabel.font = UIFont.systemFont(ofSize: 10,weight: .light)
        sendStatusImageView.contentMode = .scaleAspectFill
        sendStatusImageView.tintColor = .white
        
        dateLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        dateLabel.leadingAnchor.constraint(equalTo: leadingAnchor,constant: 5).isActive = true
        
        sendStatusImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -7).isActive = true
        sendStatusImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        sendStatusImageView.heightAnchor.constraint(equalToConstant: 8).isActive = true
        sendStatusImageView.widthAnchor.constraint(equalToConstant: 9).isActive = true
    }
    
    func setupRecievedTextViews() {
        
        self.addSubview(dateLabel)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.textAlignment = .right
        dateLabel.font = UIFont.systemFont(ofSize: 10,weight: .light)
        dateLabel.widthAnchor.constraint(equalToConstant: 30).isActive = true
        dateLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        dateLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    }
    
    func setupSendedTextViews() {
        addSubview(dateLabel)
        addSubview(sendStatusImageView)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        sendStatusImageView.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.textAlignment = .right
        sendStatusImageView.tintColor = .systemGray2
        dateLabel.font = UIFont.systemFont(ofSize: 10,weight: .light)
        sendStatusImageView.contentMode = .scaleAspectFill
        
        dateLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        dateLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        
        sendStatusImageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        sendStatusImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        sendStatusImageView.heightAnchor.constraint(equalToConstant: 8).isActive = true
        sendStatusImageView.widthAnchor.constraint(equalToConstant: 9).isActive = true
    }
}

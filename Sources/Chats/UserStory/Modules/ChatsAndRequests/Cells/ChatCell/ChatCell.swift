//
//  ActiveChatCell.swift
//  diffibleData
//
//  Created by Arman Davidoff on 20.02.2020.
//  Copyright © 2020 Arman Davidoff. All rights reserved.
//
import UIKit
import DesignSystem
import ModelInterfaces

protocol ChatCellOuput: AnyObject {
    func removeChat(at cell: UICollectionViewCell)
}

protocol ChatCellViewModelProtocol {
    var id: String { get }
    var imageURL: String { get }
    var userName: String? { get }
    var lastMessageType: LastMessageContentType? { get }
    var lastMessageSendingStatus: LastMessageSendingStatus? { get }
    var lastMessageDateString: String? { get }
    var online: Bool? { get }
    var newMessagesEnable: Bool? { get }
    var newMessagesCount: Int? { get }
}

final class ChatCell: UICollectionViewCell {
    static let idCell: String = Constants.cellID
    private let containerView = UIView()
    private let nameLabel = UILabel()
    private let dateLabel = UILabel()
    private let onlineImageView = UIImageView()
    private let markMessage = UIImageView()
    private let lastMessegeLabel = UILabel()
    private let userImageView = ImageView()
    private let gradientView = Gradient()
    private let badge = Badge()
    private let deleteButton = UIButton(type: .system)
    private var containerLeadingAnchor: NSLayoutConstraint!
    private var deleteButtonWidthAnchor: NSLayoutConstraint!
    private var deleteButtonHidden = true
    weak var output: ChatCellOuput?
    
    func config(viewModel: ChatCellViewModelProtocol) {
        lastMessegeLabel.text = viewModel.lastMessageType?.description
        nameLabel.text = viewModel.userName
        userImageView.set(imageURL: viewModel.imageURL)
        dateLabel.text = viewModel.lastMessageDateString
        markMessage.image = viewModel.lastMessageSendingStatus?.image
        onlineImageView.isHidden = !(viewModel.online ?? true)
        badge.setBadgeCount(count: viewModel.newMessagesCount)
    }
    
    func animateSelect() {
        UIView.animate(withDuration: 1) {
            self.layer.backgroundColor = UIColor.systemGray5.cgColor
            UIView.animate(withDuration: 1) {
                self.layer.backgroundColor = UIColor.systemGray6.cgColor
            }
        }
    }
   
    override func prepareForReuse() {
        userImageView.image = nil
        onlineImageView.isHidden = true
        containerLeadingAnchor.constant = Constants.zero
        deleteButtonWidthAnchor.constant = Constants.zero
        markMessage.image = nil
        deleteButtonHidden = true
        badge.isHidden = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: Setup UI
private extension ChatCell {
    
    func setupViews() {
        self.backgroundColor = .systemGray6
        nameLabel.font = Constants.nameLabelFont
        
        lastMessegeLabel.font = Constants.lastMessegeLabelFont
        lastMessegeLabel.numberOfLines = 2
        lastMessegeLabel.textColor = .gray
        
        markMessage.tintColor = Constants.markMessageTintColor
        markMessage.contentMode = .scaleAspectFill
        
        onlineImageView.tintColor = Constants.onlineImageTintColor
        onlineImageView.image = UIImage(named: Constants.onlineImageName,
                                        in: Bundle.module,
                                        with: nil)
        onlineImageView.layer.cornerRadius = Constants.onlineImageCornerRadius
        onlineImageView.layer.borderWidth = Constants.onlineImageBorderWidth
        onlineImageView.layer.borderColor = self.backgroundColor?.cgColor
        onlineImageView.layer.masksToBounds = true
        
        dateLabel.textColor = Constants.dateLabelTextColor
        dateLabel.font = Constants.dateLabelFont
        
        deleteButton.backgroundColor = Constants.deleteButtonBackgroundColor
        deleteButton.setTitle(Constants.deleteButtonTitle, for: .normal)
        deleteButton.setTitleColor(.white, for: .normal)
        deleteButton.addTarget(self, action: #selector(removeChatTapped), for: .touchUpInside)
        
        userImageView.layer.cornerRadius = Constants.imageChatHeight/2
        userImageView.clipsToBounds = true
        userImageView.sizeToFit()
        userImageView.contentMode = .scaleAspectFill
        
        gradientView.layer.cornerRadius = Constants.gradiendViewCornerRadius
        
        addSubview(containerView)
        addSubview(deleteButton)
        
        containerView.addSubview(nameLabel)
        containerView.addSubview(userImageView)
        containerView.addSubview(onlineImageView)
        containerView.addSubview(lastMessegeLabel)
        containerView.addSubview(gradientView)
        containerView.addSubview(badge)
        containerView.addSubview(dateLabel)
        containerView.addSubview(markMessage)
              
        onlineImageView.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        lastMessegeLabel.translatesAutoresizingMaskIntoConstraints = false
        userImageView.translatesAutoresizingMaskIntoConstraints = false
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        badge.translatesAutoresizingMaskIntoConstraints = false
        markMessage.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func setupConstraints() {
        containerLeadingAnchor = containerView.leadingAnchor.constraint(equalTo: leadingAnchor)
        containerLeadingAnchor.isActive = true
        containerView.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor).isActive = true
        containerView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        userImageView.leadingAnchor.constraint(equalTo: self.containerView.leadingAnchor).isActive = true
        userImageView.centerYAnchor.constraint(equalTo: self.containerView.centerYAnchor).isActive = true
        userImageView.heightAnchor.constraint(equalToConstant: Constants.imageChatHeight).isActive = true
        userImageView.widthAnchor.constraint(equalToConstant: Constants.imageChatHeight).isActive = true
        
        deleteButton.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        deleteButton.heightAnchor.constraint(equalToConstant: Constants.imageChatHeight).isActive = true
        deleteButtonWidthAnchor = deleteButton.widthAnchor.constraint(equalToConstant: 0)
        deleteButton.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        deleteButtonWidthAnchor.isActive = true
        
        gradientView.trailingAnchor.constraint(equalTo: self.containerView.trailingAnchor).isActive = true
        gradientView.centerYAnchor.constraint(equalTo: self.containerView.centerYAnchor).isActive = true
        gradientView.heightAnchor.constraint(equalToConstant: Constants.imageChatHeight).isActive = true
        gradientView.widthAnchor.constraint(equalToConstant: 6).isActive = true
        
        badge.topAnchor.constraint(equalTo: self.dateLabel.bottomAnchor,constant: 8).isActive = true
        badge.trailingAnchor.constraint(equalTo: self.gradientView.leadingAnchor, constant: -10).isActive = true
        nameLabel.leadingAnchor.constraint(equalTo: userImageView.trailingAnchor, constant: 15).isActive = true
        nameLabel.topAnchor.constraint(equalTo: self.userImageView.topAnchor).isActive = true
        
        lastMessegeLabel.leadingAnchor.constraint(equalTo: userImageView.trailingAnchor, constant: 15).isActive = true
        lastMessegeLabel.trailingAnchor.constraint(equalTo: badge.leadingAnchor, constant: -8).isActive = true
        lastMessegeLabel.topAnchor.constraint(equalTo: self.containerView.centerYAnchor, constant: -UIFont.systemFont(ofSize: 15, weight: .regular).lineHeight/2).isActive = true
        
        dateLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor).isActive = true
        dateLabel.trailingAnchor.constraint(equalTo: self.gradientView.leadingAnchor, constant: -10).isActive = true
        
        markMessage.heightAnchor.constraint(equalToConstant: 10).isActive = true
        markMessage.widthAnchor.constraint(equalToConstant: 13).isActive = true
        markMessage.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor).isActive = true
        markMessage.trailingAnchor.constraint(equalTo: dateLabel.leadingAnchor, constant: -6.5).isActive = true
        
        onlineImageView.heightAnchor.constraint(equalToConstant: 18).isActive = true
        onlineImageView.widthAnchor.constraint(equalToConstant: 18).isActive = true
        onlineImageView.bottomAnchor.constraint(equalTo: userImageView.bottomAnchor, constant: 0).isActive = true
        onlineImageView.trailingAnchor.constraint(equalTo: userImageView.trailingAnchor, constant: 0).isActive = true
        
    }
}

//MARK: DeleteButton
private extension ChatCell {
    
    func setupGestures() {
        self.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(deleteButtonShow)))
    }
    
    @objc func deleteButtonShow(gesture: UIPanGestureRecognizer) {
        let x = gesture.translation(in: self).x
        switch gesture.state {
        case .changed:
            animationDeleteButton(constant: x)
        case .ended:
            deleteButtonEnd(constant: x)
        default:
            break
        }
    }
    
    func deleteButtonEnd(constant: CGFloat) {
        if constant < 0 && deleteButtonHidden {
            if -constant > self.frame.width/10 {
                showDeleteButton()
            } else {
                hideDeleteButton()
            }
        } else if constant < 0 && !deleteButtonHidden {
            showDeleteButton()
        } else if constant > 0 && !deleteButtonHidden {
            if constant > self.frame.width/10 {
                hideDeleteButton()
            } else {
                showDeleteButton()
            }
        }
    }
    
    func animationDeleteButton(constant: CGFloat) {
        if deleteButtonHidden && constant < 0 {
            deleteButtonWidthAnchor.constant = -constant
            containerLeadingAnchor.constant = constant
            self.layoutIfNeeded()
        } else if !deleteButtonHidden && constant < self.frame.width/5 {
            deleteButtonWidthAnchor.constant = self.frame.width/5 - constant
            containerLeadingAnchor.constant = -self.frame.width/5 + constant
            self.layoutIfNeeded()
        } else {
            self.deleteButtonHidden = true
            self.deleteButtonWidthAnchor.constant = 0
            self.containerLeadingAnchor.constant = 0
            UIView.animate(withDuration: 0.2) {
                self.layoutIfNeeded()
            }
            
        }
    }
    
    func showDeleteButton() {
        deleteButtonHidden = false
        deleteButtonWidthAnchor.constant = self.frame.width/5
        containerLeadingAnchor.constant = -self.frame.width/5
        UIView.animate(withDuration: 0.4) {
            self.layoutIfNeeded()
        }
    }
    
    func hideDeleteButton() {
        deleteButtonHidden = true
        deleteButtonWidthAnchor.constant = 0
        containerLeadingAnchor.constant = 0
        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
    }
    
    @objc func removeChatTapped() {
        output?.removeChat(at: self)
    }
}

private extension ChatCell {
    struct Constants {
        static let cellID = "ChatCellId"
        static let zero: CGFloat = 0
        static let messageAndContainerInset: CGFloat = 8
        static let imageChatHeight: CGFloat = 65
        static let chatHeight: CGFloat = 75
        static let nameLabelFont = UIFont.systemFont(ofSize: 16, weight: .medium)
        static let lastMessegeLabelFont = UIFont.systemFont(ofSize: 15, weight: .regular)
        static let markMessageTintColor = #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)
        static let onlineImageTintColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
        static let onlineImageName = "online"
        static let onlineImageCornerRadius: CGFloat = 9
        static let onlineImageBorderWidth: CGFloat = 4
        static let dateLabelFont = UIFont.systemFont(ofSize: 13, weight: .regular)
        static let dateLabelTextColor = UIColor.gray
        static let deleteButtonTitle = "Delete"
        static let deleteButtonBackgroundColor = UIColor.systemRed
        static let gradiendViewCornerRadius: CGFloat = 4
    }
}

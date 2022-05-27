//
//  File.swift
//  
//
//  Created by Арман Чархчян on 14.05.2022.
//

import UIKit
import Foundation
import AudioToolbox

extension UIDevice {
    
    func vibrate() {
        let feedbackSupportLevel = UIDevice.current.value(forKey: "_feedbackSupportLevel") as? Int
        if #available(iOS 10.0, *), let feedbackSupportLevel = feedbackSupportLevel, feedbackSupportLevel > 1 {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        } else {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
    }
}

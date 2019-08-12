//
//  ShareAddMusicTableViewCell.swift
//  leapsecond
//
//  Created by Jon Andersen on 9/5/17.
//  Copyright © 2017 Andersen. All rights reserved.
//

import UIKit

class MusicPickerAddTableViewCell: UITableViewCell {
    @IBOutlet var iconImageView: UIImageView!
    @IBOutlet var addMusicLabel: UILabel!

    var cellText = L10n.General.addMusic

    @objc var isLocked: Bool = true {
        didSet {
            let text = cellText + " "
            if isLocked {
                addMusicLabel.set(image: Asset.Images.starSmall.image, with: text)
            } else {
                addMusicLabel?.text = text
            }
        }
    }
}


extension UILabel {
    func set(image: UIImage, with text: String) {
        let mutableAttributedString = NSMutableAttributedString()
        
        let textString = NSAttributedString(string: text, attributes: [.font: self.font])
        mutableAttributedString.append(textString)
        
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = CGRect(x: 0, y: 0, width: 10, height: 10)
        let attachmentStr = NSAttributedString(attachment: attachment)
        mutableAttributedString.append(attachmentStr)
        
        attributedText = mutableAttributedString
    }
}

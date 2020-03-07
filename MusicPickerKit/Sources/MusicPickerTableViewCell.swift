//
//  ShareMusicTableViewCell.swift
//  leapsecond
//
//  Created by Jon Andersen on 9/5/17.
//  Copyright © 2017 Andersen. All rights reserved.
//

import UIKit

class MusicPickerTableViewCell: UITableViewCell {
	@IBOutlet var albumArtistLabel: UILabel!
	@IBOutlet var songLabel: UILabel!
	@IBOutlet var thumbnailImageView: UIImageView!
	
	var musicItem: MusicTrackValue! {
		didSet {
			musicItem.fetchImage(size: self.thumbnailImageView.frame.size) { [weak self] image in
				self?.thumbnailImageView.image = image
			}
			let albumArtist = musicItem.albumArtist
			let albumTitle = musicItem.albumTitle
			let title = musicItem.title ?? ""
			let text = [albumArtist, albumTitle].compactMap { $0 }.joined(separator: "-")
			albumArtistLabel.text = text
			songLabel.text = title
		}
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		thumbnailImageView.image = Asset.Images.music.image
	}
}

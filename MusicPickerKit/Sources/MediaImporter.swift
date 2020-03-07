//
//  MediaImporter.swift
//  Leap Second
//
//  Created by Jon Andersen on 2/20/17.
//  Copyright © 2017 Andersen. All rights reserved.
//

import Foundation
import Photos
import TLPhotoPicker

enum MediaImportType {
	case all
	case video
}

class MediaImporter: NSObject, TLPhotosPickerViewControllerDelegate {
	private var picked: ((PHAsset?) -> Void)?
	private var asset: PHAsset?
	
	var importType: MediaImportType = MediaImportType.all
	
	@objc func pick(picked: @escaping (PHAsset?) -> Void) -> UIViewController {
		self.picked = picked
		
		let picker = TLPhotosPickerViewController()
		picker.delegate = self
		var configure = TLPhotosPickerConfigure()
		if importType == MediaImportType.video {
			configure.mediaType = PHAssetMediaType.video
		}
		configure.singleSelectedMode = true
		configure.usedCameraButton = false
		picker.configure = configure
		return picker
	}
	
	func dismissPhotoPicker(withPHAssets: [PHAsset]) {
		asset = withPHAssets.first
	}
	
	func dismissComplete() {
		picked?(asset)
	}
	
	func handleNoCameraPermissions(picker _: TLPhotosPickerViewController) {}
}

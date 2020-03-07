//
//  MusicItem.swift
//  leapsecond
//
//  Created by Jon Andersen on 9/3/17.
//  Copyright © 2017 Andersen. All rights reserved.
//

import Foundation
import MediaPlayer
import Photos

public struct MusicTrackTrimInformation: Equatable {
    let value: MusicTrackValue
    let identifier: String
    public let volume: Double
    public let start: Double?
    public let end: Double?
    
    public init(value: MusicTrackValue,
                identifier: String,
                volume: Double = 1.0,
                start: Double? = nil,
                end: Double? = nil){
        self.identifier = identifier
        self.value = value
        self.volume = volume
        self.start = start
        self.end = end
    }
    public static func == (lhs: MusicTrackTrimInformation, rhs: MusicTrackTrimInformation) -> Bool {
        return lhs.identifier == rhs.identifier && lhs.volume == rhs.volume &&
            lhs.start == rhs.start && lhs.end == rhs.end
    }
}

public struct MusicTrackItem: Equatable {
    public let assset: AVURLAsset
    public let trimInformation: MusicTrackTrimInformation
    
    public init(assset: AVURLAsset,
                trimInformation: MusicTrackTrimInformation) {
        self.assset = assset
        self.trimInformation = trimInformation
    }
    public static func == (lhs: MusicTrackItem, rhs: MusicTrackItem) -> Bool {
        return lhs.assset == rhs.assset && lhs.trimInformation == rhs.trimInformation
    }
}

public protocol MusicTrackValue {
    var playbackDuration: Double { get }
    var albumArtist: String? { get }
    var albumTitle: String? { get }
    var title: String? { get }
    
    @discardableResult
    func fetchAssetUrl(completionHandler: @escaping ((URL?, Error?) -> Void)) -> Task<URL>
    
    func fetchImage(size: CGSize, completionHandler: @escaping (UIImage?) -> Void)
}


enum MusicItemError: Error {
    case noMediaAvailable
}

extension MPMediaItem: MusicTrackValue {
    public func fetchImage(size: CGSize, completionHandler: @escaping (UIImage?) -> Void) {
        let image = artwork?.image(at: size)
        completionHandler(image)
    }
    
    public func fetchAssetUrl(completionHandler: @escaping ((URL?, Error?) -> Void)) -> Task<URL> {
        let task = Task<URL>(completionHandler: completionHandler)
        if let url = self.assetURL {
            task.complete(with: url)
        } else {
            task.fail(with: MusicItemError.noMediaAvailable)
        }
        return task
    }


}

extension PHAsset: MusicTrackValue {
    public var playbackDuration: Double { return duration }
    public var albumArtist: String? { return nil }
    public var albumTitle: String? { return nil }
    public var title: String? { return L10n.General.videos }

    public func fetchImage(size: CGSize, completionHandler: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        let s = CGSize(width: size.width * UIScreen.main.scale, height: size.height * UIScreen.main.scale)
        PHImageManager.default().requestImage(for: self, targetSize: s, contentMode: .aspectFill, options: options) { image, _ in
            completionHandler(image)
        }
    }
    
    public func fetchAssetUrl(completionHandler: @escaping ((URL?, Error?) -> Void)) -> Task<URL> {
        let task = Task<URL>(completionHandler: completionHandler)
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
        let requestId = PHImageManager.default().requestAVAsset(forVideo: self, options: options) { (asset, _, info) -> Void in
            if let asset = asset as? AVURLAsset {
                task.complete(with: asset.url)
            } else {
                task.fail(with: MusicItemError.noMediaAvailable)
            }
        }
        task.onCancel = {
            PHImageManager.default().cancelImageRequest(requestId)
        }
        
        return task
    }
}

//
//  MusicTrimViewController.swift
//  leapsecond
//
//  Created by Jon Andersen on 9/2/17.
//  Copyright © 2017 Andersen. All rights reserved.
//

import AVFoundation
import FDWaveformView
import MediaPlayer
import UIKit

internal let bundle = Bundle(for: MusicTrimViewController.classForCoder())

protocol MusicTrimViewControllerDelegate: class {
    func didFinishTrimming(musicItem: MusicTrackTrimItem)
}

class MusicTrimViewController: UIViewController, FDWaveformViewDelegate, UIScrollViewDelegate {
    var trimItem: MusicTrackTrimItem!
    private var musicItem : MusicTrackValue {
        get {
            return trimItem.value
        }
    }
    weak var delegate: MusicTrimViewControllerDelegate?

    @IBOutlet var cancelButton: UIBarButtonItem!
    @IBOutlet var useButton: UIBarButtonItem!
    @IBOutlet var thumbnailView: UIImageView!
    @IBOutlet var songNameLabel: UILabel!
    @IBOutlet var artistAlbumLabel: UILabel!
    @IBOutlet var playButton: UIButton!
    @IBOutlet var waveView: FDWaveformView!
    @IBOutlet var waveScrollView: UIScrollView!
    @IBOutlet var volumeSlider: UISlider!
    
    private let playImage = Asset.Images.play.image
    private let pauseImage = Asset.Images.pause.image

    private var player: AVPlayer?
    private var timeObserver: AnyObject?
    private var duration: Double = 0
    private var currentTime: Double = 0 {
        didSet {
            let currentTime = floor(CGFloat(self.currentTime))
            currentTimeLabel.text = formatTime(currentTime, showMiliSeconds: false)
            remainingTimeLabel.text = "-\(formatTime(ceil(CGFloat(duration)) - currentTime, showMiliSeconds: false))"
        }
    }

    private var endTime: Double = 0 {
        didSet {
            endTimeButton.setTitle("\(L10n.General.end) \(formatTime(CGFloat(endTime), showMiliSeconds: false))", for: .normal)
            updateWaveForm()
        }
    }

    private var startTime: Double = 0 {
        didSet {
            startTimeButton.setTitle("\(L10n.General.start) \(formatTime(CGFloat(startTime), showMiliSeconds: false))", for: .normal)
            updateWaveForm()
        }
    }

    private var volume: Float = 0 {
        didSet {
            player?.volume = volume
        }
    }

    @IBOutlet var endTimeButton: UIButton!
    @IBOutlet var startTimeButton: UIButton!

    @IBOutlet var remainingTimeLabel: UILabel!
    @IBOutlet var currentTimeLabel: UILabel!

    private var playing: Bool! {
        didSet {
            let icon: UIImage
            if playing {
                icon = pauseImage
                player?.play()
            } else {
                icon = playImage
                player?.pause()
            }
            playButton.setImage(icon, for: .normal)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        waveView.wavesColor = Asset.Colors.lightBackground.color
        waveView.progressColor = Asset.Colors.darkBackground.color
        startTimeButton.tintColor = Asset.Colors.textDark.color
        endTimeButton.tintColor = Asset.Colors.textDark.color
        
        
        waveScrollView.delegate = self

        volumeSlider.maximumValue = 1.0
        volumeSlider.minimumValue = 0.0

        let offImage = UIImage(named: "volumeOff", in: bundle, compatibleWith: nil)!
        let maxImage = UIImage(named: "volumeUp", in: bundle, compatibleWith: nil)!

        volumeSlider.minimumValueImage = offImage
        volumeSlider.maximumValueImage = maxImage
        volumeSlider.value = Float(trimItem.volume)

        waveView.isUserInteractionEnabled = false

        musicItem.fetchAssetUrl { [weak self] (url, error) in
            if let url = url {
                self?.player = AVPlayer(url: url)
                self?.waveView.audioURL = url
                self?.configurePeriodicTimeObserving()
            } else if let error = error {
                let errorController = createErrorController(error: error)
                self?.present(errorController, animated: true, completion: nil)
            }
        }

    

        waveView.delegate = self
        duration = musicItem.playbackDuration
        startTime = 0
        endTime = duration
        currentTime = 0
        volume = Float(trimItem.volume)

        playing = false

        playButton.setTitle(nil, for: .normal)
        playButton.tintColor = UIColor.white
        playButton.backgroundColor = UIColor.black
        playButton.clipsToBounds = true

        musicItem.fetchImage(size: thumbnailView.frame.size) { [weak self] image in
            self?.thumbnailView.image = image
        }

        let albumArtist = musicItem.albumArtist ?? ""
        let albumTitle = musicItem.albumTitle ?? ""
        let title = musicItem.title ?? ""
        artistAlbumLabel.text = "\(albumArtist) - \(albumTitle)"
        songNameLabel.text = title

        startTimeButton.layer.borderWidth = 1.0
        startTimeButton.layer.borderColor = UIColor.black.cgColor

        endTimeButton.layer.borderWidth = 1.0
        endTimeButton.layer.borderColor = UIColor.black.cgColor

        // Do any additional setup after loading the view.
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playButton.layer.cornerRadius = playButton.frame.size.width / 2.0
        startTimeButton.layer.cornerRadius = 8.0
        endTimeButton.layer.cornerRadius = 8.0
    }

    @IBAction func playTap(_: UIButton) {
        player?.seek(to: CMTimeMakeWithSeconds(currentTime, preferredTimescale: 60), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        playing = !playing
    }

    @IBAction func startButtonOnTap(_: UIButton) {
        if currentTime < endTime {
            startTime = currentTime
        } else {
            endTime = startTime
            startTime = currentTime
        }
    }

    @IBAction func endButtonOnTap(_: Any) {
        if currentTime > startTime {
            endTime = currentTime
        } else {
            startTime = endTime
            endTime = currentTime
        }
    }

    @IBAction func closeOnTap(_: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func useOnTap(_: UIBarButtonItem) {
        delegate?.didFinishTrimming(musicItem: MusicTrackTrimItem(value: musicItem, volume: Double(volume), start: startTime, end: endTime))
        self.dismiss(animated: true, completion: nil)
    }

    private func updateWaveForm() {
        if duration == 0 || startTime > endTime {
            return
        }
        let totalSamples = Double(waveView.totalSamples)

        let endPercentage = min(1.0, endTime / duration)
        let startPercentage = max(0.0, startTime / duration)
        waveView.highlightedSamples = Int(totalSamples * startPercentage) ..< Int(totalSamples * endPercentage)
    }

    func waveformViewDidLoad(_: FDWaveformView) {
        startTime = trimItem.start ?? 0.0
        endTime = trimItem.end ?? duration
        updateWaveForm()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let percentage = scrollView.contentOffset.x / scrollView.frame.width
        currentTime = duration * Double(percentage)
    }

    @IBAction func volumeChanged(_ sender: UISlider) {
        volume = sender.value
    }

    private func configurePeriodicTimeObserving() {
        let mainQueue = DispatchQueue.main
        timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 33, timescale: 1000), queue: mainQueue, using: { [weak self] (currentTime) -> Void in
            guard let self = self else {
                return
            }
            let currentTime = CMTimeGetSeconds(currentTime)
            self.currentTime = currentTime
            let width = self.waveScrollView.frame.size.width
            self.waveScrollView.contentOffset.x = width * CGFloat(currentTime / self.duration)
        }) as AnyObject?
    }
    
 

}


func formatTime(_ time: CGFloat, showMiliSeconds: Bool = true) -> String {
    if time.isNaN {
        return ""
    }
    let actualTime = max(time, 0.0)
    
    let minutes: Int = Int(actualTime.truncatingRemainder(dividingBy: 3600) / 60)
    let seconds: Int = Int(actualTime.truncatingRemainder(dividingBy: 3600).truncatingRemainder(dividingBy: 60))
    let milliseconds = Int(100 * (actualTime - floor(actualTime)))
    
    if showMiliSeconds {
        return String(format: "%02d:%02d:%02d", minutes, seconds, milliseconds)
    } else {
        return String(format: "%02d:%02d", minutes, seconds)
    }
}


func createErrorController(error: Error, title: String? = nil) -> UIAlertController {
    let controller = UIAlertController(title: title ?? L10n.General.error, message: error.localizedDescription, preferredStyle: .alert)
    let dismissAction = UIAlertAction(title: L10n.General.ok, style: .default, handler: { _ in
        controller.dismiss(animated: true, completion: nil)
    })
    controller.addAction(dismissAction)
    return controller
}

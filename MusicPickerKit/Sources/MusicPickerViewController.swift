//
//  ShareSettingsViewController.swift
//  leapsecond
//
//  Created by Jon Andersen on 9/3/17.
//  Copyright © 2017 Andersen. All rights reserved.
//

import UIKit
import MediaPlayer

public protocol MusicPickerViewControllerDelegate: class {
    func musicPickerViewControllerHasPremiumAccess(_ viewController: MusicPickerViewController) -> Bool
    func musicPickerViewController(_ viewController: MusicPickerViewController, grantPremiumAccess: @escaping ((Bool) -> ()))
    func musicPickerViewController(_ viewController: MusicPickerViewController, didPickItems musicItems: [MusicTrackItem])
}

public class MusicPickerViewController: UIViewController {

    public weak var delegate: MusicPickerViewControllerDelegate?
    
    private var mediaImporter: MediaImporter = MediaImporter()
    
    public var singleMusicItem: Bool = false

    
    public class func pickMusic(musicItems: [MusicTrackItem], delegate: MusicPickerViewControllerDelegate?, singleMusicItem: Bool = false) -> UIViewController {
        let navigationController = StoryboardScene.Main.initialScene.instantiate()
        let viewController = navigationController.viewControllers.first as! MusicPickerViewController
        viewController.musicItems = musicItems
        viewController.delegate = delegate
        viewController.singleMusicItem = singleMusicItem
        return navigationController
    }

    var musicItems: [MusicTrackItem] = []

    @IBOutlet var tableView: UITableView!

    override public func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.dataSource = self

        let cancelBarButton = UIBarButtonItem(image: Asset.Images.closeBlack.image, style: .plain, target: self, action: #selector(cancelClicked(_:)))
        cancelBarButton.tintColor = Asset.Colors.textDark.color
        navigationItem.setLeftBarButton(cancelBarButton, animated: false)
    }

    func addMusicItem(musicItem: MusicTrackItem) {
        if(singleMusicItem){
            musicItems = [musicItem]
            tableView.reloadData()
        } else {
            tableView.beginUpdates()
            let indexPath = IndexPath(row: musicItems.count, section: 0)
            musicItems.append(musicItem)
            tableView.insertRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
        }
       
    }

    @objc func cancelClicked(_: Any) {
        delegate?.musicPickerViewController(self, didPickItems: musicItems)
    }

    
}

extension MusicPickerViewController: UITableViewDataSource, UITableViewDelegate {
    public func numberOfSections(in _: UITableView) -> Int {
        return 2
    }

    public func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return musicItems.count
        } else {
            return 2
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MusicPickerTableViewCell", for: indexPath) as! MusicPickerTableViewCell
            cell.musicItem = musicItems[indexPath.row].trimInformation.value
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MusicPickerAddTableViewCell", for: indexPath) as! MusicPickerAddTableViewCell
            if indexPath.row == 0 {
                cell.cellText = L10n.General.addMusic
                cell.iconImageView.image = Asset.Images.appleMusic.image
            } else {
                // TODO: L10n
                cell.cellText = "Import from photos"
                cell.iconImageView.image = Asset.Images.photos.image
            }

            cell.isLocked = delegate?.musicPickerViewControllerHasPremiumAccess(self) != true
            return cell
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            trim(musicTrack: musicItems[indexPath.row].trimInformation)
        } else {
            let importAction: (() -> Void)
            if indexPath.row == 0 {
                importAction = importMusic
            } else {
                importAction = importFromPhotos
            }
            if(delegate?.musicPickerViewControllerHasPremiumAccess(self) == true){
                importAction()
            } else {
                self.delegate?.musicPickerViewController(self, grantPremiumAccess: { (success) in
                    if success {
                        importAction()
                    }
                })
            }
        }
    }
    
    private func importMusic() {
        let mediaPicker = MPMediaPickerController(mediaTypes: .music)
        mediaPicker.modalPresentationStyle = .overFullScreen
        mediaPicker.allowsPickingMultipleItems = false
        mediaPicker.showsCloudItems = true
        mediaPicker.delegate = self
        present(mediaPicker, animated: true, completion: {})
    }
    
    private func importFromPhotos() {
        mediaImporter = MediaImporter()
        mediaImporter.importType = .video
        let picker = mediaImporter.pick { [weak self] asset in
            if let asset = asset {
                self?.trim(musicTrack: MusicTrackTrimInformation(value: asset))
            }
        }
        picker.modalPresentationStyle = .overFullScreen
        present(picker, animated: true, completion: nil)
    }
    

    func didEdit(musicItem: MusicTrackItem) {
        if let existingItemIndex = musicItems.firstIndex(where: { (item: MusicTrackItem) -> Bool in
            musicItem.trimInformation.value.identifier == item.trimInformation.value.identifier
        }) {
            musicItems[existingItemIndex] = musicItem
        } else {
            addMusicItem(musicItem: musicItem)
        }
    }

    public func tableView(_: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row < musicItems.count
    }

    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
            tableView.beginUpdates()
            musicItems.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
        }
    }
}


extension MusicPickerViewController: MusicTrimViewControllerDelegate {
    func didFinishTrimming(musicItem: MusicTrackItem) {
        didEdit(musicItem: musicItem)
    }
}

extension MusicPickerViewController: MPMediaPickerControllerDelegate {
    public func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true, completion: nil)
    }
    
    public func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        if let mediaItem = mediaItemCollection.items.first {
            if mediaItem.hasProtectedAsset {
                let alertController = UIAlertController(title: L10n.Music.SongUnavailable.title, message: L10n.Music.SongUnavailable.description, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: L10n.General.ok, style: .default, handler: { _ in
                    alertController.dismiss(animated: true, completion: nil)
                })
                alertController.addAction(defaultAction)
                mediaPicker.present(alertController, animated: true, completion: nil)
            } else if mediaItem.isCloudItem {
                let alertController = UIAlertController(title: L10n.Music.Download.title, message: L10n.Music.Download.description, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: L10n.General.ok, style: .default, handler: { _ in
                    alertController.dismiss(animated: true, completion: nil)
                })
                let musicUrl = URL(string: "music://")!
                if UIApplication.shared.canOpenURL(musicUrl) {
                    let openMusicApp = UIAlertAction(title: L10n.Music.appOpen, style: .default, handler: { _ in
                        alertController.dismiss(animated: true, completion: nil)
                        UIApplication.shared.open(musicUrl, options: [:], completionHandler: nil)
                    })
                    alertController.addAction(openMusicApp)
                }
                
                alertController.addAction(defaultAction)
                mediaPicker.present(alertController, animated: true, completion: nil)
            } else if let _ = mediaItem.assetURL {
                let trimItem = MusicTrackTrimInformation(value: mediaItem)
                mediaPicker.dismiss(animated: true, completion: {
                    self.trim(musicTrack: trimItem)
                })
            } else {
                mediaPicker.dismiss(animated: true, completion: nil)
            }
        } else {
            mediaPicker.dismiss(animated: true, completion: nil)
        }
    }
    
    private func trim(musicTrack: MusicTrackTrimInformation){
        let trimNavigationController = StoryboardScene.Main.musicTrimNavigationViewController.instantiate()
        let viewController = trimNavigationController.viewControllers.first as! MusicTrimViewController
        viewController.trimItem = musicTrack
        viewController.delegate = self
        self.present(trimNavigationController, animated: true, completion: nil)
    }
}


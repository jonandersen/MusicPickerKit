//
//  MusicPickerTableViewController.swift
//  MusicPickerKit
//
//  Created by Jon Andersen on 12/12/19.
//  Copyright © 2019 Jon Andersen. All rights reserved.
//

import UIKit
import MediaPlayer

class MusicPickerTableViewController: UITableViewController {
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    var musicItems: [MusicTrackItem] = []
    weak var musicPickerDelegate: MusicPickerViewControllerDelegate?
    var singleMusicItem: Bool = false

    private var mediaImporter: MediaImporter = MediaImporter()
    
    private var container: MusicPickerViewController {
        get {
            return parent as! MusicPickerViewController
        }
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.dataSource = self
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
    
    override public func viewWillAppear(_ animated: Bool) {
       super.viewWillAppear(animated)
       if #available(iOS 13.0, *) {
          navigationController?.navigationBar.setNeedsLayout()
       }
    }
    
    @IBAction func doneButtonOnTap(_ sender: Any) {
        container.dismiss(animated: true, completion: nil)
        musicPickerDelegate?.musicPickerViewController(container, didPickItems: musicItems)
    }

    override func numberOfSections(in _: UITableView) -> Int {
        return 2
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return musicItems.count
        } else {
            return 2
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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

            cell.isLocked = musicPickerDelegate?.musicPickerViewControllerHasPremiumAccess(container) != true
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
            if(musicPickerDelegate?.musicPickerViewControllerHasPremiumAccess(container) == true){
                importAction()
            } else {
                self.musicPickerDelegate?.musicPickerViewController(container, grantPremiumAccess: { (success) in
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
                self?.trim(musicTrack: MusicTrackTrimInformation(value: asset,
                                                                 identifier: UUID().uuidString))
            }
        }
        picker.modalPresentationStyle = .overFullScreen
        present(picker, animated: true, completion: nil)
    }
    

    func didEdit(musicItem: MusicTrackItem) {
        if let existingItemIndex = musicItems.firstIndex(where: { (item: MusicTrackItem) -> Bool in
            musicItem.trimInformation.identifier == item.trimInformation.identifier
        }) {
            musicItems[existingItemIndex] = musicItem
        } else {
            addMusicItem(musicItem: musicItem)
        }
    }

    override func tableView(_: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row < musicItems.count
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
            tableView.beginUpdates()
            musicItems.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
        }
    }
}


extension MusicPickerTableViewController: MusicTrimViewControllerDelegate {
    func didFinishTrimming(musicItem: MusicTrackItem) {
        didEdit(musicItem: musicItem)
    }
}

extension MusicPickerTableViewController: MPMediaPickerControllerDelegate {
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true, completion: nil)
    }
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
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
                let trimItem = MusicTrackTrimInformation(value: mediaItem, identifier: UUID().uuidString)
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

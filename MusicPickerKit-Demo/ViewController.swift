//
//  ViewController.swift
//  MusicPickerKit-Demo
//
//  Created by Jon Andersen on 8/11/19.
//  Copyright © 2019 Jon Andersen. All rights reserved.
//

import UIKit
import MusicPickerKit

class ViewController: UIViewController, MusicPickerViewControllerDelegate  {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let viewController = MusicPickerViewController.pickMusic(musicItems: [], delegate: self, singleMusicItem: true)
        present(viewController, animated: true, completion: nil)
    }


    func musicPickerViewControllerHasPremiumAccess(_ viewController: MusicPickerViewController) -> Bool {
        return true
    }
    func musicPickerViewController(_ viewController: MusicPickerViewController, grantPremiumAccess: @escaping ((Bool) -> ())) {
        grantPremiumAccess(true)
        
    }
    func musicPickerViewController(_ viewController: MusicPickerViewController, didPickItems musicItems: [MusicTrackItem]) {
        
    }
}


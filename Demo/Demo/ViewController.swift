//
//  ViewController.swift
//  Demo
//
//  Created by Bro.chao on 2018/11/29.
//  Copyright © 2018 王世超. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func openAction(_ sender: UIButton) {
        BCPhotoRecord.show(option: .all, with: self) { (images, url) in
            
        }
    }
}


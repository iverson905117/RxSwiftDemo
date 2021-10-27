//
//  TestViewController.swift
//  RxSwiftDemo
//
//  Created by i_vickang on 2021/10/27.
//  Copyright © 2021 AppChihPin. All rights reserved.
//

import UIKit
import RxSwift

class TestViewController: UIViewController {
    
    var testButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // test release
        testButton = UIButton(frame: CGRect(x: 100, y: 100, width: 100, height: 50))
        testButton.backgroundColor = .gray
        testButton.setTitle("Test", for: .normal)
        view.addSubview(testButton)
        
        testButton.rx.tap.subscribe(onNext: { [unowned self] in
            self.dismiss(animated: true, completion: nil)
        })
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

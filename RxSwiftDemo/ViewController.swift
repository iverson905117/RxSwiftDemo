//
//  ViewController.swift
//  RxSwiftDemo
//
//  Created by 康志斌 on 2020/4/20.
//  Copyright © 2020 AppChihPin. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {

    @IBOutlet weak var button: UIButton!
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        retryTest()
    }

    func retryTest() {
        var retryCount = 0
        
        let retrySeq = Single<String>.create { single in
            print("retryCount: \(retryCount)")
            if retryCount >= 3 {
                single(.success("success"))
            } else {
                single(.error(RxError.unknown))
            }
            retryCount += 1
            return Disposables.create()
        }.retry(5)
        
        retrySeq
            .debug()
            .subscribe(
                onSuccess: { _ in print("success") },
                onError: { _ in print("error")})
            .disposed(by: disposeBag)
    }
}


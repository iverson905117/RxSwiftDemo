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
//        retryTest()
//        test2()
//        test3()
        test4()
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
    
    func test2() {
        
        let first = Observable<String>.just("default")
        let second = PublishSubject<String>()
        let third = PublishSubject<String>()
            
        let cancel = Observable.merge(first, second.asObservable(), third.asObservable())
            .map { (value) -> Observable<String> in
                switch value {
                case "default":
                    return Observable.just(value).delay(.seconds(5), scheduler: MainScheduler.instance)
                case "2":
                    return Observable.just(value)
                case "3":
                    return Observable.just(value)
                default:
                    return Observable.just("error")
                }
            }
            .switchLatest()
            .share()
        
        cancel.subscribe(onNext: {
            print($0)
        }).disposed(by: disposeBag)
        
        second.onNext("2")
        third.onNext("3")
    }
    
    func test3() {
        
        let first = Observable<String>.just("default")
        let second = BehaviorRelay<String>(value: "second-1")
        
        let index = Observable.merge(first, second.asObservable())
        
        index.debug("f").subscribe().dispose()
        
        let a = index.flatMapLatest { return Observable.just($0) }
        a.debug("a").subscribe().dispose()
        
        let b = index.flatMapLatest { return Observable.just($0) }
        b.debug("b").subscribe().dispose()
        
        let c = index.map { $0 }
        c.debug("c").subscribe().dispose()
        
        let d = index.withLatestFrom(second)
        d.debug("d").subscribe().dispose()
        
        
        
        second.accept("second-2")
    }
    
    func test4() {
        
        let first = Observable.just("first")
        let second = Observable.just("second")
        let third = Observable.just("third")
        
        
        Observable.combineLatest(first, second, third).subscribe(onNext: {
            print($0)
        }).disposed(by: disposeBag)
        
//        first.onNext("first")
//        second.onNext("second")
//        third.onNext("third")
    }
}


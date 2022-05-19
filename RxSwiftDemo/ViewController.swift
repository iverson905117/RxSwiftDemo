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
    
    class TestModel {
        var id: String
        var flag: Bool = false
    
        init(id: String) {
            self.id = id
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let first = PublishSubject<TestModel>()
//
//        Observable.zip(first, first.skip(1))
//            .subscribe(onNext: {
//                print("\($0.0.id)-\($0.0.flag)")
//                print("\($0.1.id)-\($0.1.flag)")
//            }).disposed(by: disposeBag)
//
//        let test1 = TestModel(id: "1")
//        let test2 = TestModel(id: "2")
//        let test3 = TestModel(id: "3")
//
//        first.onNext(test1)
//        first.onNext(test2)
//        test2.flag = true
//        first.onNext(test3)
//
//        count(from: 10, to: 5, quickStart: true).subscribe(onNext: {
//            print($0)
//        }, onCompleted: {
//            print("complete")
//        })
        
        retryTest()
//        test2()
//        test3()
//        test4()
    }
    
    func count(from: Int, to: Int, quickStart: Bool) -> Observable<Int> {
        return Observable<Int>
            .timer(quickStart ? 0 : 1, period: 1, scheduler: MainScheduler.instance)
            .take(from - to + 1)
            .map { from - $0 }
    }

    func retryTest() {
        var retryCountForTest = 0
        let maxRetryCount = 2
        
        let retrySeq = Single<String>.create { single in
            if retryCountForTest == 3 {
                single(.success("success"))
            } else {
                single(.error(RxError.unknown))
            }
            retryCountForTest += 1
            return Disposables.create()
        }
        
        retrySeq
            .observeOn(MainScheduler.asyncInstance)
            .retryWhen { (rxError: Observable<Error>) -> Observable<Int> in
                return rxError.enumerated().flatMap { (index, error) -> Observable<Int> in
                    print("retry index: \(index)")
                    guard index < maxRetryCount else { // 超過最大次數就拋出錯誤
                        return Observable.error(RxError.unknown)
                    }
                    return Observable<Int>.timer(.seconds(2), scheduler: MainScheduler.instance) // delay 2 秒
//                    return Observable.just("").asObservable().map{_ in return () }
                }
            }
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
        
//        index.debug("f").subscribe().dispose()
        
        let a = index.flatMapLatest { return Observable.just($0) }
        a.debug("a").subscribe().dispose()
//
//        let b = index.flatMapLatest { return Observable.just($0) }
//        b.debug("b").subscribe().dispose()
//
//        let c = index.map { $0 }
//        c.debug("c").subscribe().dispose()
//
//        let d = index.withLatestFrom(second)
//        d.debug("d").subscribe().dispose()
        
        
        
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


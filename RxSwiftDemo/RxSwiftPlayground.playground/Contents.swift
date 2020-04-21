import UIKit
import RxSwift
import RxCocoa

let disposeBag = DisposeBag()


// Observable 可監聽序列
// Event: onNext, onError, onCompleted

_ = Observable<String>.of("Observable")

_ = Observable<String>.just("Observable")

let observable = Observable<Int>.create({ observer -> Disposable in
    observer.onNext(0)
    observer.onNext(1)
    observer.onNext(3)
    //observer.onError(<#T##error: Error##Error#>)
    observer.onCompleted()
    return Disposables.create()
})
// 衍伸用法
observable
    .observeOn(MainScheduler.instance) // 確保在主線程
    .catchErrorJustReturn(0) // 錯誤被處理，這樣不會終止整個序列
_ = observable.asSingle()
_ = observable.asMaybe()
_ = observable.asDriver(onErrorJustReturn: 1)
_ = observable.asSignal(onErrorJustReturn: 1)

let button = UIButton()
let d: Observable<Void> = button.rx.tap.asObservable()
d.subscribe(onNext: { tap in
    print("tap")
}, onError: { error in
    print("error")
}, onCompleted: {
    print("compolete")
}).disposed(by: disposeBag)



// Single
// Event: onSuccess || onError

_ = Single.just("Single")

func getSingle() -> Single<Bool> {
    return Single<Bool>.create { single in
        single(.success(true))
        return Disposables.create()
    }
}
let single: Single<Bool> = getSingle()
single.subscribe(onSuccess: { success in
    // success
}, onError: { error in
    // error
}).disposed(by: disposeBag)



// Completable
// Event: onComplete || onError

func catchLocally() -> Completable {
    let success = true
    return Completable.create { completable in
        guard success else {
//            completable(.error(gotError))
            return Disposables.create()
        }
        completable(.completed)
        return Disposables.create()
    }
}
catchLocally()
    .subscribe(onCompleted: {
        // completed
    }, onError: { error in
        // error
    })
    .disposed(by: disposeBag)


// Maybe
// Event: onSuccess || onCompleted || onError

_ = Maybe.just("Maybe")

func generateString() -> Maybe<String> {
    return Maybe.create { maybe in
        maybe(.success("RxSwift"))
        // or
        maybe(.completed)
        // or
//        maybe(.error(error))
        return Disposables.create()
    }
}

generateString()
    .subscribe(onSuccess: { element in
        // success
    }, onError: { error in
        // error
    }, onCompleted: {
        // completed
    })
    .disposed(by: disposeBag)



// Driver 它主要是為了簡化UI層的代碼
// 不會產生 error 事件
// 一定在MainScheduler監聽（主線程監聽）
// https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/rxswift_core/observable/driver.html

_ = Driver.of("Driver")
let driver = Driver.just("Driver")
let label = UILabel()
driver.drive(label.rx.text) // Driver 版本的 bindTo
//print(label.text!)

let textField = UITextField()
let result: Driver<String> = textField.rx.text.orEmpty.asDriver()
    .throttle(RxTimeInterval.milliseconds(300))
    .flatMapLatest { query -> Driver<String> in
        print(query)
        return .just(query)
    }
textField.text = "111"
textField.text = "222"
result.drive(label.rx.text).disposed(by: disposeBag)
print("Label: \(label.text!)")

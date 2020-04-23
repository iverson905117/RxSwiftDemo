import UIKit
import RxSwift
import RxCocoa

let disposeBag = DisposeBag()

// ==================================
// Observable 可監聽序列
// ==================================
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

let button = UIButton()
let tap: Observable<Void> = button.rx.tap.asObservable()
tap
    .subscribe(onNext: { tap in
        print("tap")
    }, onError: { error in
        print("error")
    }, onCompleted: {
        print("compolete")
    }).disposed(by: disposeBag)

// 衍伸用法
observable
    .observeOn(MainScheduler.instance) // 確保在主線程
    .catchErrorJustReturn(0) // 錯誤被處理，這樣不會終止整個序列
_ = observable.asSingle()
_ = observable.asMaybe()
_ = observable.asDriver(onErrorJustReturn: 1)
_ = observable.asSignal(onErrorJustReturn: 1)



// Single
// Event: onSuccess || onError
// 不會共享附加作用

_ = Single.just("Single")

func getSingle() -> Single<Bool> {
    return Single<Bool>.create { single in
        single(.success(true))
        // or
//        single(.error(<#T##Error#>))
        return Disposables.create()
    }
}
let single = getSingle()
single
    .subscribe(onSuccess: { success in
        // success
    }, onError: { error in
        // error
    }).disposed(by: disposeBag)

_ = single.asObservable()
_ = single.asDriver(onErrorJustReturn: false)
_ = single.asMaybe()
_ = single.asCompletable()
_ = single.asSignal(onErrorJustReturn: false)


// Completable
// Event: onComplete || onError
// 不會共享附加作用

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
let completable = catchLocally()
completable
    .subscribe(onCompleted: {
        // completed
    }, onError: { error in
        // error
    })
    .disposed(by: disposeBag)



// Maybe
// Event: onSuccess || onCompleted || onError
// 不會共享附加作用

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
// 共享附加作用
// https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/rxswift_core/observable/driver.html
// Driver 會對新觀察者回放（重新發送）上一個元素 https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/rxswift_core/observable/signal.html

_ = Driver.of("Driver")
let driver = Driver.just("Driver")

let label = UILabel()
driver.drive(label.rx.text) // 主程序綁定 UI
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



// Signal
// Signal和Driver相似，唯一的區別是，Driver 會對新觀察者回放（重新發送）上一個元素，而Signal 不會對新觀察者回放上一個元素。
// 不會產生 error 事件
// 一定在MainScheduler監聽（主線程監聽）
// 共享附加作用
// https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/rxswift_core/observable/signal.html
let event: Signal<Void> = button.rx.tap.asSignal()
let observer: () -> Void = { print("彈出提示框1") }
event.emit(onNext: observer)
// ... 假设以下代码是在用户点击 button 后运行
let newObserver: () -> Void = { print("彈出提示框2") }
event.emit(onNext: newObserver) // 不會回放給新觀察者



// ControlEvent
// ControlEvent專門用於描述UI控件所產生的事件，它具有以下特徵：
// 不會產生error事件
// 一定在MainScheduler訂閱（主線程訂閱）
// 一定在MainScheduler監聽（主線程監聽）
// 共享附加作用


// ==================================


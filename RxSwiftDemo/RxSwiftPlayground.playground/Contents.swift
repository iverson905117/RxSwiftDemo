import UIKit
import RxSwift
import RxCocoa

let disposeBag = DisposeBag()

// ==================================
//       Observable 可監聽序列
// ==================================

/*
 * Event: onNext, onError, onCompleted
 */

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



// -----------------------
//         Single
// -----------------------

/*
 - Event: onSuccess || onError
 - 不會共享附加作用
 - 適合用於 Network
 */

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



// -----------------------
//      Completable
// -----------------------

/*
 - Event: onComplete || onError
 - 不會共享附加作用
 */

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



// -----------------------
//         Maybe
// -----------------------

/*
 - Event: onSuccess || onCompleted || onError
 - 不會共享附加作用
 */

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



// -------------------------------
//            Driver
// -------------------------------

/*
 - 不會產生 error 事件
 - 一定在MainScheduler監聽（主線程監聽）
 - 共享附加作用
 - 它主要是為了簡化UI層的代碼
 - https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/rxswift_core/observable/driver.html
 - Driver 會對新觀察者回放（重新發送）上一個元素
 - https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/rxswift_core/observable/signal.html
 */

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



// -----------------------
//         Signal
// -----------------------

/*
 - Signal 和 Driver 相似，唯一的區別是，Driver 會對新觀察者回放（重新發送）上一個元素，而Signal 不會對新觀察者回放上一個元素。
 - 不會產生 error 事件
 - 一定在MainScheduler監聽（主線程監聽）
 - 共享附加作用
 */

// https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/rxswift_core/observable/signal.html
let event: Signal<Void> = button.rx.tap.asSignal()
let observer: () -> Void = { print("彈出提示框1") }
event.emit(onNext: observer)
// ... 假設以下代碼是在用戶單擊按鈕後運行
let newObserver: () -> Void = { print("彈出提示框2") }
event.emit(onNext: newObserver) // 不會回放給新觀察者



// -----------------------
//      ControlEvent
// -----------------------

/*
 - ControlEvent專門用於描述UI控件所產生的事件，它具有以下特徵：
 - 不會產生error事件
 - 一定在MainScheduler訂閱（主線程訂閱）
 - 一定在MainScheduler監聽（主線程監聽）
 - 共享附加作用
 */




// ==================================
//          Observer 觀察者
// ==================================


// -----------------------
//      AnyObserver
// -----------------------

/*
 * 可以使用描敘任意一種觀察者
 */

let anyObserver: AnyObserver<String> = AnyObserver { (event) in
    switch event {
    case .next(let text):
        print(text)
    case .error(let error):
        print(error.localizedDescription)
    default:
        break
    }
}
textField.rx.text.orEmpty
    .subscribe(anyObserver)
    .disposed(by: disposeBag)


// -----------------------
//         Binder
// -----------------------

/*
 - 不會處理錯誤事件
 - 確保綁定都是在給定Scheduler上執行（默認MainScheduler）
 */

textField.text = "112"
let nameValid = textField.rx.text
    .orEmpty
    .asObservable()
    .flatMapLatest { text -> Driver<Bool> in
        return .just(text.count <= 3)
}
let binder = Binder<Bool>(textField) { (view, isHidden) in
    print("hidden: \(isHidden)")
    view.isHidden = isHidden
}
nameValid
    .bind(to: binder)
    .disposed(by: disposeBag)



// ============================================
//  Observable & Observer 既是可監聽序列也是觀察者
// ============================================

/*
 * 可作為可監聽序列
 */

let textObserverble = textField.rx.text.orEmpty
textObserverble // skip(1) 可忽略第一次訂閱
    .subscribe(onNext: { text in
        print("🐶\(text)")
    })
    .disposed(by: disposeBag)

/*
 * 也可作為觀察者
 */

let textObserver = textField.rx.text.orEmpty
let text = Observable.of("test")
text.bind(to: textObserver) // text.skip(1) 可忽略第一次綁定
print("🐼\(String(describing: textField.text))")

// 有許多UI控件都存在這種特性，例如：switch的開關狀態，segmentedControl的索引索引號，datePicker的約會日期等等。



// -----------------------
//      AsyncSubject
// -----------------------
// https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/rxswift_core/observable_and_observer/async_subject.html

/*
 * AsyncSubject將在源Observable產生完成事件後，發出最後一個元素（僅只有最後一個元素），
 * 如果源Observable沒有發出任何元素，只有一個完成事件。那AsyncSubject也只有一個完成事件。
 */

// --- 1 --- 2 --- 3 --- | --->
//  ↑ ------------------ 3 -|->
//              ↑ ------ 3 -|->

/*
 * 它源於最初的觀察者發出最終元素。如果源Observable因為產生了一個錯誤事件而中止，AsyncSubject就不會發出任何元素，而是將這個錯誤事件發送出來。
 */

// --- 1 --- 2 --- 3 --- X --->
//  ↑ ------------------ X --->
//              ↑ ------ X --->

let asyncSubject = AsyncSubject<String>()

asyncSubject
  .subscribe { print("AsyncSubject: 1 Event:", $0) }
  .disposed(by: disposeBag)

asyncSubject.onNext("🐶")
asyncSubject.onNext("🐱")
asyncSubject.onNext("🐹")
asyncSubject.onCompleted()



// -----------------------
//     PublishSubject
// -----------------------
// https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/rxswift_core/observable_and_observer/publish_subject.html

/*
 * PublishSubject將對觀察者發送訂閱後產生的元素，而在訂閱前發出的元素將不會發送給觀察者。如果您希望觀察者接收到所有的元素，
 * 您可以通過使用Observable的create方法來創建Observable， 或者使用ReplaySubject。
 */

// --- 1 --- 2 --- 3 --- | --->
//  ↑  1 --- 2 --- 3 --- | --->
//              ↑  3 --- | --->

/*
 * 如果源Observable因為產生了一個錯誤事件而中止，PublishSubject就不會發出任何元素，而是將這個錯誤事件發送出來
 */

// --- 1 --- 2 --- X --->
//  ↑  1 --- 2 --- X --->
//              ↑  X --->

let publishSubject = PublishSubject<String>()
publishSubject
    .subscribe { print("PublishSubject: 1 Event:", $0) }
    .disposed(by: disposeBag)

publishSubject.onNext("🐶")
publishSubject.onNext("🐱")

publishSubject
    .subscribe { print("PublishSubject: 2 Event:", $0) }
    .disposed(by: disposeBag)

publishSubject.onNext("🅰️")
publishSubject.onNext("🅱️")



// ---------------------
//    PublishRelay
// ---------------------

/*
 * PublishRelay 就是 PublishSubject 去掉终止事件 onError 或 onCompleted。
 * https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/recipes/rxrelay.html
 */

let publishRelay = PublishRelay<String>()
publishRelay
    .subscribe { print("PublishRelay Event:", $0) }
    .disposed(by: disposeBag)

publishRelay.accept("🐶")
publishRelay.accept("🐱")


// -----------------------
//     ReplaySubject
// -----------------------

/*
 * ReplaySubject將對觀察者發送全部的元素，無論觀察者是何時進行訂閱的。
 * 這裡存在多個版本的ReplaySubject，有的只會將最新的n個元素發送給觀察者，有的只會限制時間段內最新的元素發送給觀察者。
 * 如果把ReplaySubject當作觀察者來使用，注意不要在多個線程調用onNext，onError或onCompleted。這樣會導致無序調用，將導致意想不到的結果。
 * https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/rxswift_core/observable_and_observer/replay_subject.html
 */

// --- 1 --- 2 --- 3 --- | --->
//  ↑  1 --- 2 --- 3 --- | --->
//             ↑ 1 2 3 - | --->

let replaySubject = ReplaySubject<String>.create(bufferSize: 1)
replaySubject
    .subscribe { print("ReplaySubject: 1 Event:", $0) }
    .disposed(by: disposeBag)

replaySubject.onNext("🐶")
replaySubject.onNext("🐱")

replaySubject
    .subscribe { print("ReplaySubject: 2 Event:", $0) }
    .disposed(by: disposeBag)

replaySubject.onNext("🅰️")
replaySubject.onNext("🅱️")



// -----------------------
//     BehaviorSubject
// -----------------------
// https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/rxswift_core/observable_and_observer/behavior_subject.html


/*
 * 當觀察者對BehaviorSubject進行訂閱時，它重新合併源Observable中最新的元素發送出來（如果不存在最新的元素，就發出替換元素）。然後將隨之產生的元素發送出來。
 */

// Default = 9
// --- 1 --- 2 --- 3 --- | --->
// ↑ 9 1 --- 2 --- 3 --- | --->
//             ↑ 2 3 --- | --->

/*
 * 如果源Observable因為產生了一個錯誤事件而中止，BehaviorSubject就不會發出任何元素，而是將這個錯誤事件發送出來。
 */

// Default = 9
// --- 1 --- X --------------->
// ↑ 9 1 --- X
//             ↑ X ----------->

let behaviorSubject = BehaviorSubject<String>(value: "🔴")
behaviorSubject
    .subscribe { print("BehaviorSubject: 1 Event:", $0) }
    .disposed(by: disposeBag)

behaviorSubject.onNext("🐶")
behaviorSubject.onNext("🐱")

behaviorSubject
    .subscribe { print("BehaviorSubject: 2 Event:", $0) }
    .disposed(by: disposeBag)

behaviorSubject.onNext("🅰️")
behaviorSubject.onNext("🅱️")

behaviorSubject
    .subscribe { print("BehaviorSubject: 3 Event:", $0) }
    .disposed(by: disposeBag)

behaviorSubject.onNext("🍐")
behaviorSubject.onNext("🍊")



// ---------------------
//    BehaviorRelay
// ---------------------

/*
 * BehaviorRelay 就是 BehaviorSubject 去掉终止事件 onError 或 onCompleted。
 * https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/recipes/rxrelay.html
 */

let behaviorRelay = BehaviorRelay<String>(value: "🥎")
behaviorRelay
    .subscribe { print("BehaviorRelay Event:", $0) }
    .disposed(by: disposeBag)

behaviorRelay.accept("🐶")
behaviorRelay.accept("🐱")



// ---------------------
//    ControlProperty
// ---------------------

/*
 專門用於描述UI控件屬性的，它具有以下特徵：

 - 不會產生錯誤事件
 - 一定在MainScheduler訂閱（主線程訂閱）
 - 一定在MainScheduler監聽（主線程監聽）
 - 共享附加作用
 */




// ==========================
//     Operator - 操作符
// ==========================

/*
 * 操作符可以幫助大家創建新的序列，或者變化組合原有的序列，從而生成一個新的序列。
 */



// -------------------------
//        filter
// -------------------------

/*
 * 僅僅發出 Observable 中通過判定的元素
 * filter 操作符將通過你提供的判定方法過濾一個 Observable
 * https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/decision_tree/filter.html
 */

// - 2 - 30 - 22 - 5 - 60 - 1 ----- | --->
// filter ( x => x > 10)
// ----- 30 - 22 ----- 60 ----------| --->

Observable.of(2, 30, 22, 5, 60, 1)
    .filter { $0 > 10 }
    .subscribe(onNext: { print($0) })
    .disposed(by: disposeBag)



// -------------------------
//           map
// -------------------------

/*
 * 通過一個轉換函數，將 Observable 的每個元素轉換一遍
 * map 操作符將源 Observable 的每個元素應用你提供的轉換方法，然後返回含有轉換結果的 Observable。
 * 可傳任意型別的東西
 * 你可以用 map 創建一個新的序列。這個序列將原有的 JSON 轉換成 Model 。這種轉換實際上就是解析 JSON 。
 * https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/decision_tree/map.html
 */

// - 1 - 2 - 3 ----- | --->
// map ( x => "x" )
// -"1"-"2"-"3"----- | --->

Observable.of(1, 2, 3)
    .map { "int conver to string: \($0)" }
    .subscribe(onNext: { print($0) })
    .disposed(by: disposeBag)




// -------------------------
//           zip
// -------------------------

/*
 * 通過一個函數將多個 Observables 的元素組合起來，然後將每一個組合的結果發出來
 * 最多不超過 8 個
 */

let first = PublishSubject<String>()
let second = PublishSubject<String>()

// 合成
Observable.zip(first, second, resultSelector: { $0 + $1 })
    .subscribe(onNext: { print("zip1 Event: \($0)") })
    .disposed(by: disposeBag)
// 1A
// 2B

// 不合成
Observable.zip(first, second)
    .subscribe(onNext: { print("zip2 Event: \($0), \($1)") })
    .disposed(by: disposeBag)
// 1, A
// 2, B

first.onNext("1")  // second 無第一個元素，不會觸發觀察者
second.onNext("A") // first, second 皆有第一個元素，會觸發觀察者
first.onNext("3")  // second 無第二個元素，不會觸發觀察者

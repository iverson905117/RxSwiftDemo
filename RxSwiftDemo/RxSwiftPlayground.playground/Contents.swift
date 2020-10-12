import UIKit
import RxSwift
import RxCocoa

let disposeBag = DisposeBag()

let label = UILabel()
let button = UIButton()
var errorTestFlag = true
var errorTimes = 0

enum CatchError: Error {
    case test
    case tooMany
}

// ==================================
//       Observable 可監聽序列
// ==================================

/*
 - Event: onNext, onError, onCompleted
 - Cold Observable
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
 - Cold Observable
 - 適合用於 Network
 */

_ = Single.just("Single")

func getSingle() -> Single<Bool> {
    print("single...")
    return Single<Bool>.create { single in
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 2, execute: {
            single(.success(true))
        })
        // or
//        single(.error(<#T##Error#>))
        return Disposables.create()
    }
}

let single = getSingle()
single
    .subscribe(onSuccess: { success in
        // success
        print("single success")
    }, onError: { error in
        // error
        print("single error")
    })
    .disposed(by: disposeBag)

let shareSingle = single.asObservable().share()
shareSingle.debug().subscribe().dispose()
shareSingle.debug().subscribe().dispose()

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
 - Cold Observable
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
 - Cold Observable
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
 - Hot Observable
 - 它主要是為了簡化UI層的代碼
 - https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/rxswift_core/observable/driver.html
 - Driver 會對新觀察者回放（重新發送）上一個元素
 - https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/rxswift_core/observable/signal.html
 */

_ = Driver.of("Driver")
let driver = Driver.just("Driver")

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
result
    .drive(label.rx.text)
    .disposed(by: disposeBag)
print("Label: \(label.text!)")



// -----------------------
//         Signal
// -----------------------

/*
 - Signal 和 Driver 相似，唯一的區別是，Driver 會對新觀察者回放（重新發送）上一個元素，而Signal 不會對新觀察者回放上一個元素。
 - 不會產生 error 事件
 - 一定在MainScheduler監聽（主線程監聽）
 - Hot Observable
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
 - Hot Observable
 */



// ==================================
//     Hot and Cold Observables
// ==================================

/*
 -  Hot Observables: Driver, Signal, ControlEvent ...
 - Cold Observables: Single, Completable, Maybe ...
 * https://github.com/ReactiveX/RxSwift/blob/master/Documentation/HotAndColdObservables.md
 * 如果一個函數除了計算返回值以外，還有其他可觀測作用，我們就稱這個函數擁有附加作用:
 * https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/recipes/side_effects.html
 * https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/recipes/share_side_effects.html
 * https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/decision_tree/shareReplay.html
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

textField.text = "1121"
let nameValid = textField.rx.text
    .orEmpty
    .asObservable()
    .flatMapLatest { text -> Driver<Bool> in
        return .just(text.count <= 3)
    }

let anyObserver2: AnyObserver<Bool> = AnyObserver { event in
    switch event {
    case .next(let isHidden):
        print("hidden: \(isHidden)")
        textField.isHidden = isHidden
    default:
        break
    }
}
nameValid
    .bind(to: anyObserver2)
    .disposed(by: disposeBag)

// -----------------------
//         Binder
// -----------------------

/*
 - 不會處理錯誤事件
 - 確保綁定都是在給定Scheduler上執行（默認MainScheduler）
 */

textField.text = "123"
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
//publishSubject
//    .subscribe { print("PublishSubject: 1 Event:", $0) }
//    .disposed(by: disposeBag)

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



// =============================
//   Disposable - 可被清除的資源
// =============================

/*
 - Disposable
 - DisposeBag (推薦)當 清除包 被釋放的時候，清除包 內部所有 可被清除的資源（Disposable） 都將被清除。
 - takeUntil
 * https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/rxswift_core/disposable.html
 * 訂閱將被取消，並且內部資源都會被釋放
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
//         flatMap
// -------------------------

/*
 * 將 Observable 的元素轉換成其他的 Observable，然後將這些 Observables 合併
 * flatMap 操作符將源 Observable 的每一個元素應用一個轉換方法，將他們轉換成 Observables。然後將這些 Observables 的元素合併之後再發送出來。
 * 這個操作符是非常有用的，例如，當 Observable 的元素本身擁有其他的 Observable 時，你可以將所有子 Observables 的元素發送出來。
 * 必須同型別
 * https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/decision_tree/flatMap.html
 */


let flatMapFirst = BehaviorSubject(value: "first.👦🏻")
let flatMapSecond = BehaviorSubject(value: "second.🅰️")
let flatMapThird = BehaviorSubject(value: "third.⚾️")
let flatMapObservable = BehaviorRelay(value: flatMapFirst)

/// use flatMap
//flatMapObservable
//    .flatMap { $0 }
//    .subscribe(onNext: { print("✅flatMap Event: \($0)") })
//    .disposed(by: disposeBag)

flatMapObservable
    .flatMap { _ in return flatMapSecond }
    .flatMap { _ in return flatMapThird }
    .subscribe(onNext: { print("✅flatMap Event: \($0)") })
    .disposed(by: disposeBag)

/// not use flatMap
//flatMapObservable
//    .subscribe(onNext: { print("🚫flatMap Event: \($0)") })
//    .disposed(by: disposeBag)

flatMapFirst.onNext("first.🐱")
flatMapObservable.accept(flatMapSecond)
flatMapSecond.onNext("second.🅱️")
flatMapFirst.onNext("first.🐶")
flatMapObservable.accept(flatMapThird)
flatMapThird.onNext("third.🏈")
flatMapSecond.onNext("second.🅰️🅱️")
flatMapFirst.onNext("first.🐹")



// -------------------------
//       flatMapLast
// -------------------------

/*
 * 將 Observable 的元素轉換成其他的 Observable，然後取這些 Observables 中最新的一個
 * flatMapLatest 操作符將源 Observable 的每一個元素應用一個轉換方法，將他們轉換成 Observables。一旦轉換出一個新的 Observable，就只發出它的元素，舊的 Observables 的元素將被忽略掉。
 */

let flatMapLastFirst = BehaviorSubject(value: "first.👦🏻")
let flatMapLastSectond = BehaviorSubject(value: "second.🅰️")
let flatMapLastObservable = BehaviorRelay(value: flatMapLastFirst)
flatMapLastObservable
    .flatMapLatest { $0 }
    .subscribe(onNext: { print("flatMapLast Event: \($0)") })
    .disposed(by: disposeBag)

flatMapLastFirst.onNext("first.🐱")
flatMapLastObservable.accept(flatMapLastSectond)
flatMapLastSectond.onNext("second.🅱️")
flatMapLastFirst.onNext("first.🐶")



// -------------------------
//           zip
// -------------------------

/*
 * 通過一個函數將多個 Observables 的元素組合起來，然後將每一個組合的結果發出來
 * 最多不超過 8 個
 * https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/decision_tree/zip.html
 */

// 1 --- 2 --------- 3 - 4 ----- 5 ---|--->
// -- A -- B --- C D -----------------|--->
// zip
// 1A -- 2B -------- 3C - 4D ---------|--->

let zipFirst = PublishSubject<String>()
let zipSecond = PublishSubject<String>()
let zipError = PublishSubject<String>()

// 合成
Observable.zip(zipFirst, zipSecond, resultSelector: { $0 + $1 })
    .subscribe(onNext: { print("zip1 Event: \($0)") })
    .disposed(by: disposeBag)
// 1A

// 合成 Error
Observable.zip(zipFirst, zipError, resultSelector: { $0 + $1 })
    .subscribe(onNext: { print("zip2 Event: \($0)") },
               onError: { error in print("zip2 catch error") })
    .disposed(by: disposeBag)
// 1B
// catch error

// 不合成
// 可以不同型別
Observable.zip(zipFirst, zipSecond)
    .subscribe(onNext: { print("zip3 Event: \($0), \($1)") })
    .disposed(by: disposeBag)
// 1, A


zipFirst.onNext("1")
zipFirst.onNext("2")
zipFirst.onNext("3") // 不會觸發觀察者

zipSecond.onNext("A")
zipSecond.onNext("A")

zipError.onNext("B")
zipError.onError(CatchError.test) // 只要 catch error 觀察者必定觸發 onError
zipError.onNext("B")  // 已觸發 onError 觀察者被終止了



// -------------------------
//       combineLatest
// -------------------------

/*
 * 當多個 Observables 中任何一個發出一個元素，就發出一個元素。這個元素是由這些 Observables 中最新的元素，通過一個函數組合起來的
 * 元素必須同樣型別
 * https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/decision_tree/combineLatest.html
 */

// 1 -- 2 ---------- 3 - 4 --- 5 ----|--->
// -- A -- B --- C D ----------------|--->
// combineLastest x + y
// 1A - 2A - 2B - 2C 2D 3D 4D 5D ----|--->

let combineLastestFirst = PublishSubject<String>()
let combineLastestSecond = PublishSubject<String>()
// 組合
Observable
    .combineLatest(combineLastestFirst, combineLastestSecond) { $0 + $1 }
    .subscribe(onNext: { print("combineLastest1 Event: \($0)") })
    .disposed(by: disposeBag)
// 不組合
// 可以不同型別
Observable
    .combineLatest(combineLastestFirst, combineLastestSecond)
    .subscribe(onNext: { print("combineLastest2 Event: \($0), \($1)") })
    .disposed(by: disposeBag)

combineLastestFirst.onNext("1")
combineLastestSecond.onNext("A")
combineLastestFirst.onNext("2")
combineLastestSecond.onNext("B")
combineLastestSecond.onNext("C")
combineLastestSecond.onNext("D")
combineLastestFirst.onNext("3")
combineLastestFirst.onNext("4")



// -------------------------
//           amb
// -------------------------

/*
 * 在多個源 Observables 中， 取第一個發出元素或產生事件的 Observable，然後只發出它的元素
 * https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/decision_tree/amb.html
 */

let ambObservalble1 = Observable<String>.create { observer -> Disposable in
    observer.onNext("amb1-1")
    observer.onNext("amb1-2")
    observer.onCompleted()
    return Disposables.create()
}
let ambObservalble2 = Observable<String>.error(CatchError.test)
let ambObservalble3 = Observable<String>.just("amb3")

Observable<String>.amb([ambObservalble1, ambObservalble2, ambObservalble3])
    .subscribe(onNext: {
        print("ambObservable Event: \($0)")
    }, onError: { error in
        print("ambObservable error")
    }, onCompleted: {
        print("ambObservable completed")
    })
    .disposed(by: disposeBag)

/*
 當你傳入多個 Observables 到 amb 操作符時，它將取其中一個 Observable：第一個產生事件的那個 Observable，可以是一個 next，error 或者 completed 事件。 amb 將忽略掉其他的 Observables。
 */



// -------------------------
//          buffer
// -------------------------

/*
 * 緩存元素，然後將緩存的元素集合，週期性的發出來
 * buffer 操作符將緩存 Observable 中發出的新元素，當元素達到某個數量，或者經過了特定的時間，它就會將這個元素集合發送出來。
 * https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/decision_tree/buffer.html
 */

var bufferObservable = PublishSubject<String>()

//bufferObservable
//    .buffer(timeSpan: .seconds(2), count: 3, scheduler: MainScheduler.instance)
//    .subscribe(onNext: { print("buffer Event: \($0)") })
//    .disposed(by: disposeBag)

bufferObservable.onNext("1")
bufferObservable.onNext("2")
bufferObservable.onNext("3")
bufferObservable.onNext("A")
bufferObservable.onNext("B")



// -------------------------
//        catchError
// -------------------------

/*
 * 從一個錯誤事件中恢復，將錯誤事件替換成一個備選序列
 * catchError 操作符將會攔截一個 error 事件，將它替換成其他的元素或者一組元素，然後傳遞給觀察者。這樣可以使得 Observable 正常結束，或者根本都不需要結束。
 */

let errorSequence = PublishSubject<String>()
let recoverySequence = PublishSubject<String>()

errorSequence
    .catchError { error -> Observable<String> in
        print("catch error: \(error)")
        return recoverySequence
    }
    .subscribe(onNext: { print("catchError return recovery Event: \($0)") },
           onError: { print("catchError \($0)")},           // 不會觸發
           onCompleted: { print("catchError completed") })  // 不會觸發
    .disposed(by: disposeBag)

errorSequence.onNext("😬")
errorSequence.onNext("😨")
errorSequence.onNext("😡")
errorSequence.onNext("🔴")
errorSequence.onError(CatchError.test)  // 發生 error
recoverySequence.onNext("😊")           // 替換成觀察 recoverySequence
errorSequence.onNext("🥵")              // 將不繼續觀察 errorSequence
recoverySequence.onNext("😊😊")



// -------------------------
//   catchErrorJustReturn
// -------------------------

/*
 * catchErrorJustReturn 操作符會將 error 事件替換成其他的一個元素，然後結束該序列。
 */

let errorJustReturnSequence = PublishSubject<String>()

errorJustReturnSequence
    .catchErrorJustReturn("catchErrorJustReturn")
    .subscribe(onNext: { print("catchErrorJustReturn Event: \($0)") },
               onError: { print("catchErrorJustReturn error: \($0)") },
               onCompleted: { print("catchErrorJustReturn completed") }) // 接收到 Error 會觸發
    .disposed(by: disposeBag)

errorJustReturnSequence.onNext("😬")
errorJustReturnSequence.onNext("😨")
errorJustReturnSequence.onNext("😡")
errorJustReturnSequence.onNext("🔴")
errorJustReturnSequence.onError(CatchError.test)



// -------------------------
//          concat
// -------------------------

/*
 * 讓兩個或多個 Observables 按順序串連起來
 * https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/decision_tree/concat.html
 */

/*
 concat 操作符將多個 Observables 按順序串聯起來，當前一個 Observable 元素發送完畢後，後一個 Observable 才可以開始發出元素。

 concat 將等待前一個 Observable 產生完成事件後，才對後一個 Observable 進行訂閱。如果後一個是“熱” Observable ，在它前一個 Observable 產生完成事件前，所產生的元素將不會被發送出來。
 */

let concatSubject1 = BehaviorSubject(value: "1.🍎")
let concatSubject2 = BehaviorSubject(value: "1.🐶")

let concatRelay = BehaviorRelay(value: concatSubject1)

concatRelay.asObservable()
    .concat()
    .subscribe(onNext: { print("concat Event: \($0)") })
    .disposed(by: disposeBag)

concatSubject1.onNext("1.🍐")
concatSubject1.onNext("1.🍊")
concatRelay.accept(concatSubject2)
concatSubject2.onNext("2.I would be ignored")
concatSubject2.onNext("2.🐱")
concatSubject1.onCompleted() //  完成後才會訂閱後一個 Observable
concatSubject2.onNext("2.🐭")
concatSubject1.onNext("1.I am completed") // 已完成不會再被觀察



// -------------------------
//        concatMap
// -------------------------

/*
 * 將 Observable 的元素轉換成其他的 Observable，然後將這些 Observables 串連起來
 */

let concatMapSubject1 = BehaviorSubject(value: "1.🍎")
let concatMapSubject2 = BehaviorSubject(value: "1.🐶")

let concatMapRelay = BehaviorRelay(value: concatMapSubject1)

concatMapRelay.asObservable()
    .concatMap({ subject -> BehaviorSubject<String> in
//        return BehaviorSubject(value: "123")
        return subject
    })
    .subscribe(onNext: { print("concatMap Event: \($0)") })
    .disposed(by: disposeBag)

concatMapSubject1.onNext("1.🍐")
concatMapSubject1.onNext("1.🍊")
concatMapRelay.accept(concatMapSubject2)
concatMapSubject2.onNext("2.I would be ignored")
concatMapSubject2.onNext("2.🐱")
concatMapSubject1.onCompleted() //  完成後才會訂閱後一個 Observable
concatMapSubject2.onNext("2.🐭")
concatMapSubject1.onNext("1.I am completed") // 已完成不會再被觀察



// -------------------------
//          merge
// -------------------------

/*
 * 將多個 Observables 合併成一個 (同一條序列內)
 * https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/decision_tree/merge.html
 */

// - 20 - 40 - 60 - 80 - 100 -----|--->
// -------------- 1 -------- 1 ---|--->
// merge
// - 20 - 40 - 60 1 89 - 100 1 ---| --->

/*
 通過使用 merge 操作符你可以將多個 Observables 合併成一個，當某一個 Observable 發出一個元素時，他就將這個元素發出。

 如果，某一個 Observable 發出一個 onError 事件，那麼被合併的 Observable 也會將它發出，並且立即終止序列。
 */

let mergeSubject1 = PublishSubject<String>()
let mergeSubject2 = PublishSubject<String>()

// 方式一
Observable.of(mergeSubject1, mergeSubject2)
    .merge()
    .subscribe(onNext: { print("merger1 Event: \($0)") },
               onError: { print("merger1 catch error: \($0)") },
               onCompleted: { print("merger1 completed") })
    .disposed(by: disposeBag)

// 方式二
Observable
    .merge(mergeSubject1, mergeSubject2)
    .subscribe(onNext: { print("merger2 Event: \($0)") },
           onError: { print("merger2 catch error: \($0)") },
           onCompleted: { print("merger2 completed") })
    .disposed(by: disposeBag)

mergeSubject1.onNext("🅰️")
mergeSubject1.onNext("🅱️")
mergeSubject2.onNext("①")
mergeSubject2.onNext("②")
//mergeSubject1.onError(CatchError.test) // 其中一條序列 error 都會觸發 onError
//mergeSubject1.onCompleted() // 必須所有序列都 completed 才會觸發 onCompleted
//mergeSubject2.onCompleted()
mergeSubject1.onNext("🆎")
mergeSubject2.onNext("③")



// ===========================
//    Schedulers - 調度器
// ===========================

/*
 * Schedulers 是 Rx 實現多線程的核心模塊，它主要用於控制任務在哪個線程或隊列運行。
 
 - MainScheduler:
   代表主線程。如果你需要執行一些和 UI 相關的任務，就需要切換到該 Scheduler 運行。
 
 - SerialDispatchQueueScheduler:
   抽象了串行 DispatchQueue。如果你需要执行一些串行任务，可以切换到这个 Scheduler 运行。
 
 - ConcurrentDispatchQueueScheduler:
   抽象了並行 DispatchQueue。如果你需要執行一些並發任務，可以切換到這個 Scheduler 運行。
 
 - OperationQueueScheduler:
   抽象了 NSOperationQueue。它具備 NSOperationQueue 的一些特點，例如，你可以通過設置 maxConcurrentOperationCount，來控制同時執行並發任務的最大數量。
 */

// GCD
DispatchQueue.global(qos: .userInitiated).async {
    // 子線程 get image
    _ = try? UIImage(data: Data(contentsOf: URL(string: "https://")!))
    DispatchQueue.main.async {
        // 主線程 update UI
    }
}

// subscribeOn: 決定數據序列的構建函數在哪個 Scheduler 上運行。
// observeOn: 在哪個 Scheduler 監聽這個數據序列

// RxSwift 實現
behaviorRelay
    .subscribeOn(ConcurrentDispatchQueueScheduler.init(qos: .userInitiated))
    .observeOn(MainScheduler.instance)
    .subscribe(onNext: { print("Schedulers on main queue: Event: \($0)") })
    .disposed(by: disposeBag)
behaviorRelay.accept("123")



// =============================
//   Error Handling - 錯誤處理
// =============================
// https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/rxswift_core/error_handling.html

/*
 * 可以讓序列在發生錯誤後重試，達到重試次數仍錯誤，才會拋出錯誤
 */

let errorObservable = Observable<Int>.create { observer in
    if errorTimes < 100 {
        errorTimes += 1
        print("errorObservable errorTimes: \(errorTimes)")
        observer.onError(CatchError.test)
    }
    observer.onNext(1)
    return Disposables.create()
}



// --------------------
//        retry
// --------------------

/*
 * 設定最大重試次數，達到重試最大次數仍錯誤，才會拋出錯誤
 */

errorTestFlag = true
errorTimes = 0
errorObservable
    .retry(3) // 遇到 error 立即重試 次數 3 次
    .subscribe(onNext: { value in
        print("errorObservable.retry: Event: \(value)")
    }, onError: { error in
        print("errorObservable.retry catch error") // 重試 3 次後仍錯誤，就將錯誤拋出
    })
    .disposed(by: disposeBag)

// --------------------
//      retryWhen
// --------------------

/*
 * 序列發生錯誤時，經過一段時間再重試
 */

errorTestFlag = true
errorTimes = 0
errorObservable
    .retryWhen { (rxError: Observable<Error>) -> Observable<Int> in
        return Observable<Int>.timer(.microseconds(500), scheduler: MainScheduler.instance)
    }
    .subscribe(onNext: { value in
        print("errorObservable.retryWhen: Event: \(value)")
    }, onError: { error in
        print("errorObservable.retryWhen catch error")
    })
    .disposed(by: disposeBag)



// --------------------------
//     retry + retryWhen
// --------------------------

/*
 * 序列發生錯誤時，經過一段時間再重試，且超過最大次數就不再重試並拋出錯誤
 */

let maxRetryCount = 4

errorTestFlag = true
errorTimes = 0
errorObservable
    .observeOn(MainScheduler.asyncInstance)
    .retryWhen { (rxError: Observable<Error>) -> Observable<Int> in
        return rxError.enumerated().flatMap { (index, error) -> Observable<Int> in
            guard index < maxRetryCount else { // 超過最大次數就拋出錯誤
                return Observable.error(CatchError.tooMany)
//                throw CatchError.tooMany
            }
            return Observable<Int>.timer(.seconds(2), scheduler: MainScheduler.instance)
        }
    }
    .subscribe(onNext: { value in
        print("errorObservable.retryWhen with max retry: Event: \(value)")
    }, onError: { error in
        print("errorObservable.retryWhen with max retry catch error")
    })
    .disposed(by: disposeBag)

errorTestFlag = true
errorTimes = 0
errorObservable
    .observeOn(MainScheduler.asyncInstance)
    .retryWhen { (rxError: Observable<Error>) -> Observable<()> in
        return rxError.enumerated().flatMap { (index, error) -> Observable<()> in
            print(index)
            guard index < maxRetryCount else { // 超過最大次數就拋出錯誤
                return Observable.error(CatchError.tooMany)
//                throw CatchError.tooMany
            }
            return Observable.just("").asObservable().map{_ in return () }
        }
    }
    .subscribe(onNext: { value in
        print("errorObservable.retryWhen with max retry: Event: \(value)")
    }, onError: { error in
        print("errorObservable.retryWhen with max retry catch error")
    })
    .disposed(by: disposeBag)


// --------------------------
//           take
// --------------------------
Observable.of("🐱", "🐰", "🐶", "🐸", "🐷", "🐵")
    .take(1)
    .subscribe(onNext: { print("take element: \($0)") })
    .disposed(by: disposeBag)

Observable.of("🐱", "🐰", "🐶", "🐸", "🐷", "🐵")
    .takeLast(1)
    .subscribe(onNext: { print("take last element: \($0)") })
    .disposed(by: disposeBag)


// --------------------------
//           share
// --------------------------

// Share map

let seq = PublishSubject<Int>()
let seqNoShare = seq.map { value -> Int in
    // 沒 share 被訂閱一次就會被執行一次
    // 有 share 會共享
    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 2, execute: {
        print("Multiplying by 2: \(value)x2")
    })
//    print("Multiplying by 2: \(value)x2")
    return value * 2
}
let seqShare = seqNoShare.share()
let seqShareReplay = seqNoShare.share(replay: 2)

//seqNoShare.debug("first").subscribe().disposed(by: disposeBag)
//seqNoShare.debug("seconde").subscribe().disposed(by: disposeBag)

seqShare.debug("first_share").subscribe().disposed(by: disposeBag)
seqShare.debug("seconde_share").subscribe().disposed(by: disposeBag)

//seqShareReplay.debug("first_shareReplay").subscribe().disposed(by: disposeBag)
//seqShareReplay.debug("seconde_shareReplay").subscribe().disposed(by: disposeBag)

seq.onNext(2)
seq.onNext(3)

seqShareReplay.debug("third_shareReplay").subscribe().disposed(by: disposeBag)
seqShare.debug("four_share").subscribe().disposed(by: disposeBag)

seq.onCompleted()


// Share observable property

var count = 0
let shareObservable = Observable<String>.create { observer -> Disposable in
    print("Feching data...")
    count += 1
    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 2, execute: {
        observer.onNext("shareObservable test \(count)")
        observer.onCompleted() // onCompleted 前都是 shared
    })
    return Disposables.create()
}.share()

shareObservable
    .subscribe(onNext: { print($0) })
    .disposed(by: disposeBag)
shareObservable
    .subscribe(onNext: { print($0) })
    .disposed(by: disposeBag)

DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 3, execute: {
    shareObservable
        .subscribe(onNext: { print($0) })
        .disposed(by: disposeBag)
})

/*
Feching data...
shareObservable test 1
shareObservable test 1
Feching data...
shareObservable test 2
 */


// Share observable method
// note: Single success = onCompleted

func startRefreshToken() -> Observable<String> {
    return Observable<String>.create { (observer) -> Disposable in
        print("....")
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 2, execute: {
            count += 1
            observer.onNext("just a test \(count)")
            // onCompleted 前訂閱都會是 share
            observer.onCompleted()
            // onCompleted 之後訂閱都會重新執行
        })
        return Disposables.create()

    }
}

let shareStartRefreshToken = startRefreshToken().share()

// Share 訂閱
shareStartRefreshToken.subscribe(onNext: { print($0) }).disposed(by: disposeBag)
shareStartRefreshToken.subscribe(onNext: { print($0) }).disposed(by: disposeBag)
shareStartRefreshToken.subscribe(onNext: { print($0) }).disposed(by: disposeBag)

// 上一次訂閱結束後再訂閱
DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 3, execute: {
    shareStartRefreshToken.subscribe(onNext: { print($0) }).disposed(by: disposeBag)
})

/*
....
just a test 1
just a test 1
just a test 1
....
just a test 2
 */

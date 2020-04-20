import UIKit
import RxSwift
import RxCocoa

let disposeBag = DisposeBag()

// Observable 可監聽序列
// Event: onNext, onError, onCompleted
let a = Observable<String>.of("30")
let b = Observable<Bool>.just(true)
let c = Observable<Int>.create({ observer -> Disposable in
    observer.onNext(0)
    observer.onNext(1)
    observer.onNext(3)
    //observer.onError(<#T##error: Error##Error#>)
    observer.onCompleted()
    return Disposables.create()
})

let button = UIButton()
let d: Observable<Void> = button.rx.tap.asObservable()
d.subscribe(onNext: { tap in
    print("tap")
}, onError: { error in
    print("error")
}, onCompleted: {
    print("compolete")
}).disposed(by: disposeBag)


// Single 特徵序列
// Event: onSuccess, onError
// 可對 Observable 調用 .asSingle()
func getSingle() -> Single<Bool> {
    return Single<Bool>.create { single in
        single(.success(true))
        return Disposables.create()
    }
}
let e: Single<Bool> = getSingle()
e.subscribe(onSuccess: { success in
    print("success")
}, onError: { error in
    print("error")
}).disposed(by: disposeBag)


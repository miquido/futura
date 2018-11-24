import Foundation
import Futura

enum Errors: Error {
    case invalidState
    case noData
    case invalidData
}

func make(request: URLRequest) -> Future<(URLResponse, Data?)> {
    let promise = Promise<(URLResponse, Data?)>()
    URLSession.shared.dataTask(with: request) { data, resp, err in
        if let err = err {
            promise.break(with: err)
        } else if let resp = resp {
            promise.fulfill(with: (resp, data))
        } else {
            promise.break(with: Errors.invalidState) // this is invalid state that should be covered with some nice error
        }
    }.resume()
    return promise.future
}

extension String {
    static func from(data: Data) throws -> String {
        guard let string = String(data: data, encoding: .utf8) else {
            throw Errors.invalidData
        }
        return string
    }
}

let githubRequest = URLRequest(url: URL(string: "https://www.github.com")!)
make(request: githubRequest)
    .map { (_, data) -> Data in
        guard let data = data else {
            throw Errors.noData
        }
        return data
    }
    .map(String.from(data:))
    .switch(to: DispatchQueue.main)
    .value { _ in
        print("Github is here!")
    }
    .error { reason in
        print("There was an error when getting github: \(reason)")
    }

// similar to String extension we can define JSONDecoder extension for easy decoding
extension JSONDecoder {
    func decoder<T: Decodable>(for type: T.Type) -> (Data) throws -> T {
        return { data in
            try self.decode(type, from: data)
        }
    }
}

let jsonDecoder = JSONDecoder()
struct SomeDecodable: Decodable {
    let someField: String
}

let jsonRequest = URLRequest(url: URL(string: "https://www.somejson.com/json")!)

make(request: jsonRequest)
    .map { (_, data) -> Data in
        guard let data = data else {
            throw Errors.noData
        }
        return data
    }
    .map(jsonDecoder.decoder(for: SomeDecodable.self))
    .value {
        print("Some field is: \($0.someField)")
    }
    .error { reason in
        print("There was an error when getting json: \(reason)")
    }

import UIKit

var buttonTapKey: Int = 0
private class ClosureHolder<T> {
    let closure: (T?) -> Void

    init(_ closure: @escaping (T?) -> Void) {
        self.closure = closure
    }

    @objc
    func invoke(with any: Any) {
        closure(any as? T)
    }
}

struct SignalSource<Subject> {
    let subject: Subject
    init(subject: Subject) {
        self.subject = subject
    }
}

extension UIButton {
    var signal: SignalSource<UIButton> { return .init(subject: self) }
}

extension SignalSource where Subject: UIButton {
    var tap: Signal<Void> {
        if let signal = objc_getAssociatedObject(subject, &buttonTapKey) as? Emitter<Void> {
            return signal
        } else {
            let emitter: Emitter<Void> = .init()
            objc_setAssociatedObject(subject, &buttonTapKey, emitter.signal, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            let closureHolder = ClosureHolder<UIButton> { _ in
                emitter.emit(Void())
            }
            subject.addTarget(closureHolder, action: #selector(ClosureHolder<UIButton>.invoke), for: .touchUpInside)
            objc_setAssociatedObject(subject, String(format: "[%d]", arc4random()), closureHolder, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return emitter.signal
        }
    }
}

extension UITextField {
    var signal: SignalSource<UITextField> { return .init(subject: self) }
}

extension SignalSource where Subject: UITextField {
    var text: Signal<String> {
        if let signal = objc_getAssociatedObject(subject, &buttonTapKey) as? Emitter<String> {
            return signal
        } else {
            let emitter: Emitter<String> = .init()
            objc_setAssociatedObject(subject, &buttonTapKey, emitter.signal, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)

            let closureHolder = ClosureHolder<UITextField> {
                emitter.emit($0?.text ?? "")
            }
            subject.addTarget(closureHolder, action: #selector(ClosureHolder<UITextField>.invoke), for: .editingChanged)
            objc_setAssociatedObject(subject, String(format: "[%d]", arc4random()), closureHolder, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return emitter.signal
        }
    }
}

import PlaygroundSupport

enum ValidationError: Error {
    case emptyValue
    case invalidURL
    case invalidEncoding
}

func validateNotEmpty(_ string: String) throws -> String {
    guard !string.isEmpty else {
        throw ValidationError.emptyValue
    }
    return string
}

func convertToURL(_ string: String) throws -> URL {
    guard let url = URL(string: string) else {
        throw ValidationError.invalidURL
    }
    return url
}

func callURL(_ url: URL) -> Future<Data> {
    return
        make(request: .init(url: url))
        .map { (_, data) -> Data in
            guard let data = data else {
                throw Errors.noData
            }
            return data
        }
}

func decodeAsString(_ data: Data) throws -> String {
    guard let string = String(data: data, encoding: .utf8) else {
        throw ValidationError.invalidEncoding
    }
    return string
}

let view: UIView = .init(frame: .init(x: 0, y: 0, width: 200, height: 200))
view.backgroundColor = .white

let textField: UITextField = .init()
textField.frame = .init(x: 20, y: 120, width: 160, height: 80)
textField.placeholder = "Type some text..."
textField.text = "https://www.google.com"
view.addSubview(textField)

let button: UIButton = .init()
button.frame = .init(x: 20, y: 20, width: 160, height: 80)
button.setTitleColor(.blue, for: .normal)
button.setTitle("BUTTON", for: .normal)
view.addSubview(button)

textField.signal.text
    .map(validateNotEmpty)
    .map(convertToURL)
    .flatMap { url in
        return button.signal.tap.map { url }
    }
    .map(callURL)
    .values {
        $0.map(decodeAsString)
            .value {
                print("Network result:\n \($0)")
            }
            .error {
                print("Network error: \($0)")
            }
    }
    .errors {
        print("Error: \($0)")
    }

PlaygroundPage.current.liveView = view

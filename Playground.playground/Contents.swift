import Foundation
import Futura

enum Errors : Error {
    case invalidState
    case noData
    case invalidData
}

func make(request: URLRequest) -> Future<(URLResponse, Data?)> {
    let promise = Promise<(URLResponse, Data?)>()
    URLSession.shared.dataTask(with: request) { (data, resp, err) in
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

let githubRequest = URLRequest(url: URL(string: "https://www.github.com")!)
make(request: githubRequest)
    .map { (response, data) -> Data in
        guard let data = data else {
            throw Errors.noData
        }
        return data
    }
    .map { (data) -> String in
        guard let string = String(data: data, encoding: .utf8) else {
            throw Errors.invalidData
        }
        return string
    }
    .switch(to: DispatchWorker.main)
    .then { _ in
        print("Github is here!")
    }
    .fail { reason in
        print("There was an error: \(reason)")
    }

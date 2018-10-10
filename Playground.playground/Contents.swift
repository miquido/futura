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

extension String {
    static func from(data: Data) throws -> String {
        guard let string = String(data: data, encoding: .utf8) else {
            throw Errors.invalidData
        }
        return string
    }
}
let fWorker = FuturaWorker()
let githubRequest = URLRequest(url: URL(string: "https://www.github.com")!)
make(request: githubRequest)
    .map { (response, data) -> Data in
        guard let data = data else {
            throw Errors.noData
        }
        return data
    }
    .map(String.from(data:))
    .switch(to: fWorker)
    .then { _ in
        print("Github is here!")
        print("still works! -> \(fWorker.isCurrent)")
    }
    .fail { reason in
        print("There was an error when getting github: \(reason)")
    }
    .clone()
    .clone()
    .clone()
    .map {
        $0 + "!!!"
    }
    .always {
        print("still works! -> \(fWorker.isCurrent)")
    }
print("still works! -> \(fWorker.isCurrent)")
// similar to String extension we can define JSONDecoder extension for easy decoding
extension JSONDecoder {
   
    func decoder<T: Decodable>(for type: T.Type) -> (Data) throws -> T {
        return { data in
            return try self.decode(type, from: data)
        }
    }
}

let jsonDecoder = JSONDecoder()
struct SomeDecodable : Decodable {
    let someField: String
}
let jsonRequest = URLRequest(url: URL(string: "https://www.somejson.com/json")!)

make(request: jsonRequest)
    .map { (response, data) -> Data in
        guard let data = data else {
            throw Errors.noData
        }
        return data
    }
    .map(jsonDecoder.decoder(for: SomeDecodable.self))
    .then {
        print("Some field is: \($0.someField)")
    }
    .fail { reason in
        print("There was an error when getting json: \(reason)")
    }


# Futura

[![Build Status](https://api.travis-ci.org/miquido/futura.svg?branch=master)](https://travis-ci.org/miquido/futura)
[![Platforms](https://img.shields.io/badge/platform-iOS%20|%20macOS-gray.svg?style=flat)]()
[![SwiftVersion](https://img.shields.io/badge/Swift-4.2-brightgreen.svg)]()

Futura is a small library that provides simple yet powerful implementation of promises for iOS and macOS.

## Integration
Best way to use Futura library is to use git submodule
``` bash
git submodule add git@github.com:miquido/futura.git
```
or download code and copy it to your project. 
Note here that compiling generic interfaces as public cannot be optimised as good as generics in closed code base. This means that compiling Futura as part of your project instead of making it a framework can make it a little faster.

You can also use Carthage with a little less flexibility.
```
github "miquido/futura" ~> 1.1
```

Or even CocoaPods, but since this library hasn't been added yet to the official CocoaPods spec repository you must point to it explicitly.
```
pod 'Futura', :git => 'https://github.com/miquido/futura.git', :tag => '1.1.0'
```

## Usage
Future is read only wrapper around delayed / asynchronous value. 
``` swift
let future: Future<String> = ...
```
It supports both success and failure using Result type under the hood.
``` swift
future.then { value in
	print("There was a success: \(value)")
}
future.fail { reason in
	print("There was an error: \(reason)")
}
```
Promises can be used to apply result of future. Each Promise contains associated future it can complete.
``` swift
let promise: Promise<String>()
promise.future.then { value in
	print("Promise fulfilled: \(value)")
}
promise.fulfill(with: "Success") // completes with value
promise.break(with: Errors.someError) // completes with error
// calling fulfill or break on completed promise has no effect
```
Futura provides all fundamental tools to work with asynchronous code like maps and flat maps.
``` swift
future.map {
	String($0) + "!"
}
```
There are a lot of special handlers allowing flexibility and possibility to handle all interesting cases.
``` swift
future.resulted { ... } // when completed but not canceled
future.always { ... }  // when competed including canceled
future.catch { ... } // when error but not propagates further
future.recover { ... } // when error allows to provide valid value
```
It also gives you full control about thread where your code will be executed. By default futures inherit execution context from predecessors (completing Promise or chained Future).
``` swift
future
.switch(to: DispatchWorker.main)
.then { _ in
	print("Executed on main thread")
}
```
All future transformations and handlers supports chaining of operations. This allows nice to read chains of code.

## Example
Power of promises is an ability to simplify work with asynchronous code. Best example here is network call. With such a small helper function like below.
``` swift
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
```
We can achieve this without any additional dependencies.
``` swift
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
```
## Debug
Debugging asynchronous code can be hard. To make this a little bit easier Futura covers all Future events with logs when compiled with FUTURA_DEBUG flag. It uses Apple log system to do logging so you can see all logs in Console app on your mac.

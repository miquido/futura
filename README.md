# [![Futura](logo.png)]()

[![Build Status](https://api.travis-ci.org/miquido/futura.svg?branch=master)](https://travis-ci.org/miquido/futura)
[![Platforms](https://img.shields.io/badge/platform-iOS%20|%20macOS-gray.svg?style=flat)]()
[![SwiftVersion](https://img.shields.io/badge/Swift-4.2-brightgreen.svg)]()

Futura is a library that provides simple yet powerful tools for working with asynchronous and concurrent code in Swift.

## What it is about?

The main goal of Futura is to keep things simple. This means that it provides easy to use tools that have compact and understandable implementation. You should not be worried about fixing and extending any of those because of massive code base or complicated architecture. This also means that Futura does not provide ultimate solution to all concurrency problems. It only simplifies many of them with proper tool for each problem. If certain tool does not work in your case, do not try to hack it, just use the other one or propose new one if needed.

## What it is not?

Futura is not any kind of framework or complete solution. It does not provide single universal tool (like in example rx) for all problems. It also does not try to pack extra features where it not fits or feels right. It also does not provide multi layer abstraction connecting and organizing all internals. It just keeps things simple :)
This repository does not contain any platform or library specific extensions too. It should be developed outside to provide reasonable small library that have wide usage.

## Is that for me?

If you are wondering if you should use Futura in your code base please take a minute and look at sample code below. One of basic tools provided with this library is implementation of promises. With promises you can convert single asynchronous task to be more predictable and better handled. In example you can change URLSession requests like this:
``` swift
make(request: URLRequest.init(url: "www.github.com"), using: URLSession.shared) { (data, response, error) in
    if let error = error {
        DispatchQueue.main.async {
            present(error: error)
        }
    } else if let response = response, response.statusCode == 200 {
        if let data = data {
            do {
                let decodedText = try decode(from: data)
                DispatchQueue.global(qos: .background).async {
                    store(text: decodedText)
                }
                DispatchQueue.main.async {
                    present(text: decodedText)
                }
                log(count: decodedText.count)
            } catch {
                DispatchQueue.main.async {
                    present(error: error)
                }
            }
        } else {
            DispatchQueue.main.async {
                present(error: Errors.invalidResponse)
            }
        }
    } else {
        DispatchQueue.main.async {
            present(error: Errors.invalidResponse)
        }
    }
}
```
to be more like this:
``` swift
let futureData = 
    make(request: URLRequest.init(url: "www.github.com"), using: URLSession.shared)
    .map { (response, data) in
        if response.statusCode == 200 {
            return data
        } else {
            throw Errors.invalidResponse
        }
    }
    .map {
        return try decode(from: $0)
    }
futureData
    .switch(to: DispatchWorker.background)
    .then {
        store(text: $0)
    }
futureData
    .switch(to: DispatchWorker.main)
    .then {
        present(text: $0)
    }
    .fail {
        present(error: $0)
    }
futureData
    .map {
        $0.count
    }
    .then {
        log(count: $0)
    }
```
This conversion not only simplifies the code keeping the same functionality and multithreading execution but it also splits things to be more manageable and testable. Each part - database, presentation and logs - is clearly separated from each other and may be applied in different more suitable places.

For more examples and tools overview please go to "What exactly it is?" section.

## How to get it?

Best way to use Futura library is to use git submodule
``` bash
git submodule add git@github.com:miquido/futura.git
```
and integrate it with your code base.

You can also use Carthage with a little less flexibility.
```
github "miquido/futura" ~> 2.0
```

Or even CocoaPods, but since this library hasn't been added yet to the official CocoaPods spec repository you must point to it explicitly.
```
pod 'Futura', :git => 'https://github.com/miquido/futura.git', :tag => '2.0.0'
```

## What it will be in future?

Basic tools are already here. It is all tested and documented in simpliest way. This is not the end though. There are some extensions and features that will be developed in future.

 -[x] Foundation features
 -[x] Promise and future
 -[x] Promise and future tests
 -[ ] Promise and future debug system
 -[ ] Promise and future documentation (partially done)
 -[ ] Promise and future randomized test sets
 -[x] Stream 
 -[ ] Stream with buffer
 -[x] Stream tests
 -[ ] Stream debug system
 -[ ] Stream documentation (partially done)
 -[ ] Stream randomized test sets
 -[ ] Swift Package Manager support
 -[ ] Linux support
 -[ ] Custom worker implementation

## What exactly it is? TODO:

What excact tools are available in Futura? 
Single async tasks and even caches can be done with promises and futures. 
Continous event streams and user inputs can be converted into ??? to be easier to use and manage. 
Futura gives you also nice and fast recursive lock and fastest possible mutex implementation via easy to use pthread_mutex wrapper.

### Worker

Worker is a fundamental tool of Futura. It is abstraction on execution of tasks that allows to use any kind of threading solution. If you need any custom scheduling or thread implementation you can conform to Worker protocol and use that one in your code base. There is no implicit or forced usage of any concrete Worker across all tools (with some exceptions in using DispatchWorker as default argument in some functions). DispatchWorker is simple implementation of worker using DispatchQueue that is currently used as default one. Usage of this simple abstraction allowed to simplify a lot of unit tests by using fully predictable task execution solution.

### Promise and future

Future is read only wrapper around delayed / asynchronous value. 
``` swift
let future: Future<String>
```
It supports both success and failure that can be accessed and handled wit ease.
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
	print("Promise fulfilled with: \(value)")
}
promise.fulfill(with: "Success") // completes with value
promise.break(with: Errors.someError) // completes with error
// calling fulfill or break on finished promise has no effect
```
If for any reason you need to drop handling and cancel all scheduled tasks without executing it you can to do so.
``` swift
promise.cancel() // cancels future associated with this promise and all of it children future instances
future.cancel() // cancels this future and all of it children future instances, it does not affect its parent future
// after calling cancel future becomes finished, cannot be completed or canceled anymore and does not call any handlers except `always`
```
Futures provides all fundamental tools to work with them like maps and flat maps and other special handlers allowing flexibility and possibility to cover all interesting cases.
``` swift
future.map { // can change type of future
	String($0) + "!"
}

future.flatMap { // can change not only type but also join two futures to one
	return someAsyncTask(with: $0) // needs to return Future
}

future.completed { ... } // when completed with value or error but not canceled
future.always { ... }  // when finished (completed or canceled)
future.catch { ... } // when error but not propagates further
future.recover { ... } // when error allowing to provide valid value
```
It also gives you full control about thread on which your code will be executed. By default futures inherit execution context from predecessors (completing Promise or chained Future). This means that worker used to complete or cancel promise will be used to execute all its handlers. In case of already finished future if there is no explicit worker associated with it handler will be executed immediately on current thread.
``` swift
future
.switch(to: DispatchWorker.main)
.then { _ in
	print("Executed on main thread")
}
```
All future transformations and handlers supports chaining of operations. This allows nice to read chains of code.

Power of promises is an ability to simplify work with asynchronous code. Best example here is network call from the beginning of this readme. It was possible by such a small helper function like below.
``` swift
func make(request: URLRequest, using session: URLSession) -> Future<(URLResponse, Data?)> {
    let promise = Promise<(URLResponse, Data?)>()
    session.dataTask(with: request) { (data, resp, err) in
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

### Stream TODO:

### Lock and mutex TODO:

## License
TODO:

# [![Futura](logo.png)]()

[![Build Status](https://api.travis-ci.org/miquido/futura.svg?branch=master)](https://travis-ci.org/miquido/futura)
[![Platforms](https://img.shields.io/badge/platform-iOS%20|%20macOS-gray.svg?style=flat)]()
[![SwiftVersion](https://img.shields.io/badge/Swift-4.2-brightgreen.svg)]()

Futura is a library that provides simple yet powerful tools for working with asynchronous and concurrent code in Swift.

## What it is about?

The main goal of Futura is to keep things simple. This means that it provides easy to use yet flexible tools that have compact and understandable implementation. You should not be worried about fixing and extending any of those because of massive code base or complicated architecture. This also means that Futura does not provide ultimate solution to all concurrency problems. It only simplifies many of them with proper tool for each problem.

## What it is not about?

Futura is not any kind of framework. It does not provide single universal solution for all problems yet available tools are flexible enough to cover most cases. It also does not try to pack extra features where it not fits or feels right. This repository does not contain any platform or library specific extensions too.

## Is that for me?

If you are wondering if you should use Futura in your code base or what it is actually about please take a minute and look at sample code below. One of basic tools provided with this library is implementation of promises. With promises you can convert single asynchronous task to be more predictable and better handled. In example you can change URLSession requests like this:
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
    .failure {
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

One more example - in this case we will cover second important feature which is Signal. Signals provide api for dealing with continous streams of data and errors emited by some source. It might be user interactions, status observation or even socket.
``` swift
TODO: to complete
```

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

Basic tools are already here. It is all tested and documented. This is not the end though. There are some extensions and features that will be developed in future.

- [x] DispatchWorker
- [x] Recursive lock
- [x] Promise and future
- [ ] Promise and future debug system
- [ ] Promise and future documentation (partially done)
- [ ] Promise and future randomized test sets
- [x] Stream TODO: naming
- [ ] Stream with buffer TODO: naming
- [ ] Stream debug system TODO: naming
- [ ] Stream documentation (partially done) TODO: naming
- [ ] Stream randomized test sets TODO: naming
- [ ] Swift Package Manager support
- [ ] Linux support
- [ ] FuturaWorker (custom worker implementation optimized for futures)
 
## What exactly it is? TODO: to complete

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
future.failure { reason in
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
// calling fulfill or break on finished (completed or canceled) promise has no effect
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

future.complete { ... } // when completed with value or error but not canceled
future.always { ... }  // when finished (completed or canceled)
future.catch { ... } // when error but not propagates further
future.recover { ... } // when error allowing to provide valid value
```
It also gives you full control about thread on which your code will be executed. By default futures inherit execution context from predecessors (completing Promise or chained Future). This means that worker used to complete or cancel promise will be used to execute all its handlers. In case of already finished future if there is no explicit worker associated with it handler will be executed immediately on current thread.
``` swift
future
.switch(to: DispatchWorker.main)
.then { _ in 
    // it is guaranteed that it will be executed by worker selected before
	// event if adding handler on already completed future
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

You can also make simplified futures without promise. Just like this:
``` swift
future { // it will be performed on selected worker - dafault is DispatchWorker.default
	// some task that will be done in future
	return result // or throw to mark error
}.complete {
	// future completed
}
```

### Signal TODO: to complete and naming

### Lock and Mutex

In case you need some sychronization in your code you can use custom recursive lock implementation based on pthread_mutex.
``` swift
let lock: RecursiveLock = .init()
lock.synchronized {
	// all operations inside are synchronized by this lock
}
```
If you need to use mutex directly you can do it simple using nice wrapper. It is not recommended though. If you still for some reason will use this remember that it is only functions wrapper, you need to dealocate it manually.
``` swift
let mutex = Mutex.create() // returns pointer to instance of pthread_mutex
Mutex.lock(mutex)
Mutex.unlock(mutex)
Mutex.destroy(mutex) // since it is just function wrapper, not object you have to deallocate it manually
```

## How to get involved?

Since Futura is open source project you can feel invited to make it even better. If you have found any kind of bug please make an issue. If any part of documentation is missing or not comperhensive propose some change or describe it as an issue. If you feel that there is smoething can be done better just fork this repository and propose some changes!

## License

Copyright 2018 Miquido

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

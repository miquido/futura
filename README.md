# [![Futura](logo.jpeg)]()

[![Build Status](https://api.travis-ci.org/miquido/futura.svg?branch=master)](https://travis-ci.org/miquido/futura)
[![codecov](https://codecov.io/gh/miquido/futura/branch/master/graph/badge.svg)](https://codecov.io/gh/miquido/futura)
[![Platforms](https://img.shields.io/badge/platform-iOS%20|%20iPadOS%20|%20macOS-gray.svg?style=flat)]()
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![SwiftVersion](https://img.shields.io/badge/Swift-5.1-brightgreen.svg)]()

Futura is a library that provides simple yet powerful tools for working with asynchronous and concurrent code in Swift.

## What it is about?

The main goal is to keep things simple and swifty. This means that it provides easy to use and flexible tools while not being afraid of diving deep into primitives. Futura does not provide an ultimate solution to all concurrency problems. It only simplifies many of them with a proper tool for each problem. The secondary goal of this library is to allow easy testing of asynchronous code. Everything is not only designed to be testable but there is also an additional library, dedicated to improve testing of asynchronous code.

## What it is not about?

Futura is not any kind of framework. It does not provide a single universal solution for all problems but available tools are flexible enough to cover most cases. It also does not try to pack extra features were it not fits or feels right. This repository does not contain any platform or library specific extensions too. You can although find some use cases and examples in the attached Playground.

## Is that for me?

If you are wondering if you should use Futura in your code base or what it is actually about please take a minute and look at the sample code below. One of the basic tools provided with this library is the implementation of promises. With promises, you can convert a single asynchronous task to be more predictable and better handled. In the example you can change URLSession requests like this:

``` swift
make(request: URLRequest(url: "www.github.com"), using: URLSession.shared) { (data, response, error) in
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
    make(request: URLRequest(url: "www.github.com"), using: URLSession.shared)
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
    .switch(to: DispatchQueue.global(qos: .background))
    .value {
        store(text: $0)
    }
futureData
    .switch(to: DispatchQueue.main)
    .value {
        present(text: $0)
    }
    .error {
        present(error: $0)
    }
futureData
    .map {
        $0.count
    }
    .value {
        log(count: $0)
    }
```

This conversion not only simplifies the code keeping the same functionality and multithreading execution but it also splits things to be more manageable and testable. Each part - database, presentation, and logs - are clearly separated from each other and may be applied in different more suitable places.

For more usage examples please look at attached Playground.

## How to get it?

Swift package manager is currently best solution to use:

``` swift
.package(url: "https://github.com/miquido/futura.git", from: "2.0.0")
```

You can use Futura as git submodule

``` bash
git submodule add https://github.com/miquido/futura.git
```

and integrate it with your code base manually.


You can also use Carthage:

```
github "miquido/futura" ~> 2.0
```

You can even use CocoaPods, but since this library hasn't been added to the official CocoaPods spec repository you must point to it explicitly.

```
pod 'Futura', :git => 'https://github.com/miquido/futura.git', :tag ~> '2.0'
```

## What it is exactly?

Futura consists of a set of tools that helps you manage asynchronous and concurrent code.

### Worker

Worker is a fundamental tool of Futura. It is an abstraction on execution of tasks that allows using any kind of threading solution. If you need any custom scheduling or thread implementation you can conform to Worker protocol and use that one in your code base. There is no implicit or forced usage of any concrete Worker across all tools (with one exception). Proper usage of workers allows you to write completely synchronous unit tests. No more XCTestExpectation or timeouts, just look how Futura is tested internally.

### Synchronization

There are some useful helpers here. Easy to use pthread_mutex wrapper (Mutex) and even easier to use Lock and RecursiveLock based on it. All of those are used internally to provide fast and reliable synchronization. There is also property wrapper called Synchronized to make synchronized properties more easily.

### Atomics

Currently, there is only one atomic here. It is easy to use atomic_flag wrapper - AtomicFlag.

### Future

For tasks that are performed only once, there is a nice and performant promise implementation. It enables you to make your code better organized and easier to read. Especially useful when dealing with network requests, database transactions, and other one time tasks.

### Signal

If you have continuous stream of data or unpredictable events you should use Signal. It allows you to react to events or transform data that comes asynchronously. It works really nice for handling user interactions or network data streams. Note here that it is not Rx implementation, it is not compatible and behaves differently than it.

### FuturaTest

It is a set of tools and extensions that help writing unit tests. You can use it to simplify asynchronous code tests (i.e. asyncTest extension for XCTestCase) or even make it synchronous in some cases (with TestWorker support). A lot of those tools are used to perform tests internally.

## How to get involved?

Since Futura is open source project you can feel invited to make it even better. If you have found any kind of bug please make an issue. If any part of the documentation is missing or not comprehensive propose some change or describe it using issue. If you feel that there is something can be done better just fork this repository and propose some changes!

## License

Copyright 2018-2020 Miquido

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

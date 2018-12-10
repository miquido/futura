# [![Futura](logo.png)]()

[![Build Status](https://api.travis-ci.org/miquido/futura.svg?branch=master)](https://travis-ci.org/miquido/futura)
[![Platforms](https://img.shields.io/badge/platform-iOS%20|%20macOS-gray.svg?style=flat)]()
[![SwiftVersion](https://img.shields.io/badge/Swift-4.2-brightgreen.svg)]()

Futura is a library that provides simple yet powerful tools for working with asynchronous and concurrent code in Swift.

## What it is about?

The main goal of Futura is to keep things simple. This means that it provides easy to use and flexible tools that have compact and understandable implementation. You should not be worried about fixing or extending any of those because of massive code base or complicated architecture. This also means that Futura does not provide ultimate solution to all concurrency problems. It only simplifies many of them with proper tool for each problem.

## What it is not about?

Futura is not any kind of framework. It does not provide single universal solution for all problems but available tools are flexible enough to cover most cases. It also does not try to pack extra features where it not fits or feels right. This repository does not contain any platform or library specific extensions too.

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
This conversion not only simplifies the code keeping the same functionality and multithreading execution but it also splits things to be more manageable and testable. Each part - database, presentation and logs - is clearly separated from each other and may be applied in different more suitable places.

For more usage examples please look at attached Playground.

## How to get it?

You can use Futura as git submodule
``` bash
git submodule add https://github.com/miquido/futura.git
```
and integrate it with your code base.

You can also use Carthage with a little less flexibility.
```
github "miquido/futura" ~> 2.0
```

You can even use CocoaPods, but since this library hasn't been added yet to the official CocoaPods spec repository you must point to it explicitly.
```
pod 'Futura', :git => 'https://github.com/miquido/futura.git', :tag => '2.0.0'
```
 
## What it is exactly?

Futura consists of a set of tools that helps you manage asynchronous and concurrent code.

### Lock

There are two helpers here. Easy to use pthread_mutex wrapper (Mutex) and even easier to use RecursiveLock based on it. Both are used internally to provide fast and reliable synchronization.

### Worker

Worker is a fundamental tool of Futura. It is abstraction on execution of tasks that allows to use any kind of threading solution. If you need any custom scheduling or thread implementation you can conform to Worker protocol and use that one in your code base. There is no implicit or forced usage of any concrete Worker across all tools (with one exception). Proper usage of workers allows you to write completely synchronous unit tests. No more XCTestExpectation or timeouts, just look how Futura is tested internally.

### Future

For tasks that are performed only once, there is a nice promise implementation. It enables you to make your code better organized and easier to read. Specially useful when dealing with network requests, database transactions and other one time tasks.

### Signal

If you have continous stream of data or unpredictable events you should use Signal. It allows you to react on events or transform data that comes asynchronously. It works really nice for handling user interactions or network data streams.


## How to get involved?

Since Futura is open source project you can feel invited to make it even better. If you have found any kind of bug please make an issue. If any part of documentation is missing or not comperhensive propose some change or describe it using issue. If you feel that there is smoething can be done better just fork this repository and propose some changes!

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

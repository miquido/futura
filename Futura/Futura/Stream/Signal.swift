/* Copyright 2018 Miquido

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License. */

public class Signal<Value> {
    internal typealias Token = Either<Error, Value>
    internal typealias Subscriber = (Either<Error?, Token>) -> Void

    private var subscriptionID: Subscription.ID = 0
    private let privateCollector: SubscriptionCollector = .init()

    internal let lock: RecursiveLock = .init()
    internal var subscribers: [Subscription.ID: Subscriber] = .init()
    internal weak var collector: SubscriptionCollector?
    internal var isFinished: Bool = false
    internal var isUnsubscribing: Bool = false

    internal init(collector: SubscriptionCollector?) {
        self.collector = collector
    }

    internal func subscribe(_ subscriber: @escaping Subscriber) -> Subscription? {
        return lock.synchronized {
            guard !isFinished else { return nil }
            let id = subscriptionID.next()
            subscribers[id] = subscriber
            return Subscription.init { [weak self] in
                guard let self = self else { return }
                self.lock.synchronized {
                    self.isUnsubscribing = true
                    self.subscribers[id] = nil
                    self.isUnsubscribing = false
                }
            }
        }
    }

    internal func broadcast(_ token: Token) {
        lock.synchronized {
            guard !isSuspended else { return }
            subscribers.sorted { $0.0 < $1.0 }.forEach { $0.1(.right(token)) } // TODO: sorted for tests? ensures calls in same order as adding handlers
        }
    }

    internal func finish(_ reason: Error? = nil) {
        lock.synchronized {
            guard !isSuspended else { return } // TODO: this suspended may prevent braodcasting finish - to check
            subscribers.sorted { $0.0 < $1.0 }.forEach { $0.1(.left(reason)) } // TODO: sorted for tests? ensures calls in same order as adding handlers
            isFinished = true
            var sub = subscribers
            // cache until end of scope to prevent deallocation of subscribers while making changes in subscribers dictionary - prevents crash
            subscribers = .init()
            sub.removeAll() // TODO: to check performance
        }
    }

    internal func collect(_ subscribtion: Subscription?) {
        guard let subscribtion = subscribtion else { return }
        if let collector = collector {
            collector.collect(subscribtion)
        } else {
            privateCollector.collect(subscribtion)
        }
    }

    // prevents broadcasting if internal state not allows this
    // i.e. in the middle of removing subscription
    // prevents a lot of crashes...
    internal var isSuspended: Bool {
        return isUnsubscribing || !(collector?.isActive ?? true) || !privateCollector.isActive
    }

    deinit { finish() }
}

public extension Signal {
    @discardableResult
    func values(_ observer: @escaping (Value) -> Void) -> Signal {
        collect(subscribe { event in
            guard case let .right(.right(value)) = event else { return }
            observer(value)
        })
        return self
    }

    @discardableResult
    func failures(_ observer: @escaping (Error) -> Void) -> Signal {
        collect(subscribe { event in
            guard case let .right(.left(value)) = event else { return }
            observer(value)
        })
        return self
    }

    // TODO: tokens - either value or error without reference

    @discardableResult
    func ended(_ observer: @escaping () -> Void) -> Signal {
        collect(subscribe { event in
            guard case .left(.none) = event else { return }
            observer()
        })
        return self
    }

    @discardableResult
    func terminated(_ observer: @escaping (Error) -> Void) -> Signal {
        collect(subscribe { event in
            guard case let .left(.some(reason)) = event else { return }
            observer(reason)
        })
        return self
    }

    @discardableResult
    func finished(_ observer: @escaping () -> Void) -> Signal {
        collect(subscribe { event in
            guard case .left = event else { return }
            observer()
        })
        return self
    }
}

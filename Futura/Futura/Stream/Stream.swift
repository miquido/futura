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

/// Stream is read only object for accessing data provided as stream.
public class Stream<Value> {

    private var nextSubscriptionID: Subscription.ID = 0
    private let privateCollector: SubscribtionCollector = .init()
    
    internal let lock: RecursiveLock = .init()
    internal var subscribers: [Subscription.ID : (Event) -> Void] = [:]
    internal weak var collector: SubscribtionCollector?
    internal var isClosed: Bool = false
    internal var isUnsubscribing: Bool = false
    
    internal init(collector: SubscribtionCollector?) {
        self.collector = collector
    }
    
    internal func subscribe(_ subscriber: @escaping (Event) -> Void) -> Subscription? {
        return lock.synchronized {
            guard !isClosed else { return nil }
            let id = nextSubscriptionID.getThenIterate()
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
    
    internal func broadcast(_ event: Event) {
        lock.synchronized {
            guard !isSuspended else { return }
            subscribers.forEach { $0.1(event) }
            cleanupIfNeeded(after: event)
        }
    }
    
    internal func cleanupIfNeeded(after event: Event) {
        switch event {
        case .close, .terminate:
            isClosed = true
            var sub = subscribers
            // cache until end of scope to prevent deallocation of subscribers while making changes in subscribers dictionary - prevents crash
            subscribers = [:]
            sub.removeAll() // TODO: to check performance
        default: break
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
    
    internal var isSuspended: Bool {
        return isUnsubscribing || collector?.isSuspended ?? false || privateCollector.isSuspended
    }
    
    deinit { broadcast(.close) }
}

extension Stream {
    
    public enum Event {
        case value(Value)
        case error(Error)
        case close
        case terminate(Error)
    }
}

public extension Stream {
    
    /// Access each value passed by this stream
    @discardableResult
    func next(_ observer: @escaping (Value) -> Void) -> Stream {
        collect(subscribe { (event) in
            guard case let .value(value) = event else { return }
            observer(value)
        })
        return self
    }
    
    /// Access each error passed by this stream
    @discardableResult
    func fail(_ observer: @escaping (Error) -> Void) -> Stream {
        collect(subscribe { (event) in
            guard case let .error(value) = event else { return }
            observer(value)
        })
        return self
    }
    
    /// Access stream closing information
    @discardableResult
    func closed(_ observer: @escaping () -> Void) -> Stream {
        collect(subscribe { (event) in
            guard case .close = event else { return }
            observer()
        })
        return self
    }
    
    /// Access stream termination information
    @discardableResult
    func terminated(_ observer: @escaping (Error) -> Void) -> Stream {
        collect(subscribe { (event) in
            guard case let .terminate(reason) = event else { return }
            observer(reason)
        })
        return self
    }
}

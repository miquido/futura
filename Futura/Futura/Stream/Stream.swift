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

public class Stream<Value> {

    private var nextSubscriptionID: Subscription.ID = 0
    private let privateCollector: SubscribtionCollector = .init()
    private var allowSubscriptions: Bool = true
    
    internal var subscribers: [Subscription.ID : (Event) -> Void] = [:]
    internal let lock: Lock = .init()
    internal weak var collector: SubscribtionCollector?
    
    internal init(collector: SubscribtionCollector?) {
        self.collector = collector
    }
    
    internal func subscribe(_ subscriber: @escaping (Event) -> Void) -> Subscription? {
        return lock.synchronized {
            guard allowSubscriptions else { return nil }
            let id = nextSubscriptionID.currentThenNext()
            subscribers[id] = subscriber
            return Subscription.init { [weak self] in
                self?.lock.synchronized {
                    self?.subscribers[id] = nil
                }
            }
        }
    }
    
    internal func broadcast(_ event: Event) {
        lock.synchronized {
            subscribers.forEach { $0.1(event) }
            
            // TODO: what to do with subscribers after close / terminate?
            if case .close = event {
                allowSubscriptions = false
                subscribers = [:]
            } else if case .terminate = event {
                allowSubscriptions = false
                subscribers = [:]
            } else { /* nothing */ }
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
    
    deinit {
        lock.synchronized { allowSubscriptions = false }
        // TODO: adding subscription while on deinit may cause crash - to check
        broadcast(.close)
    }
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
    
    @discardableResult
    func next(_ observer: @escaping (Value) -> Void) -> Stream {
        collect(subscribe { (event) in
            guard case let .value(value) = event else { return }
            observer(value)
        })
        return self
    }
    
    @discardableResult
    func fail(_ observer: @escaping (Error) -> Void) -> Stream {
        collect(subscribe { (event) in
            guard case let .error(value) = event else { return }
            observer(value)
        })
        return self
    }
    
    @discardableResult
    func closed(_ observer: @escaping () -> Void) -> Stream {
        collect(subscribe { (event) in
            guard case .close = event else { return }
            observer()
        })
        return self
    }
    
    @discardableResult
    func terminated(_ observer: @escaping (Error) -> Void) -> Stream {
        collect(subscribe { (event) in
            guard case let .terminate(reason) = event else { return }
            observer(reason)
        })
        return self
    }
}

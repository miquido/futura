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

/// SubscribtionCollector is object that holds and collects subscriptions
/// created by transforming and observing streams.
/// Subscriptions are managed internally and valid until SubscribtionCollector used
/// for collecting subscriptions is not deallocated.
/// All associated subscriptions are removed when deallocating SubscribtionCollector instance.
/// You can delegate ownership of subscriptions to any owned collector by collect method.
public final class SubscribtionCollector {
    
    private let lock: Lock = .init()
    private var subscribtions: [Subscription] = []
    
    internal var isSuspended: Bool = false
    
    public init() {}
    
    internal func collect(_ subscribtion: Subscription) {
        lock.synchronized {
            guard !isSuspended else { return }
            subscribtions.append(subscribtion)
        }
    }
    
    // TODO: it might be public?
    internal func unsubscribeAll() {
        lock.synchronized {
            isSuspended = true
            subscribtions.forEach { $0.unsubscribe() }
            isSuspended = false
        }
    }
    
    deinit {
        lock.synchronized {
            isSuspended = true
            subscribtions.forEach { $0.unsubscribe() }
        }
        // TODO: adding subscription while on deinit may cause crash - to check
    }
}

extension Stream {
    
    /// Starting at this point all transformations and observations
    /// will be managed by provided SubscribtionCollector until next collect call.
    /// Returns new instance of Stream that will propagate collector to its children.
    public func collect(with collector: SubscribtionCollector) -> Stream {
        let next = ForwardingStream<Value, Value>.init(source: self, collector: collector)
        next.collect(subscribe {
            next.broadcast($0)
        })
        return next
    }
}

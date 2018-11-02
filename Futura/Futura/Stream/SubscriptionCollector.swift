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

public final class SubscriptionCollector {
    
    private let lock: RecursiveLock = .init()
    private var subscriptions: [Subscription] = .init()
    
    internal var finished: Bool = false
    
    public init() {}
    
    internal func collect(_ subscription: Subscription) {
        lock.synchronized {
            guard !finished else { return }
            subscriptions.append(subscription)
        }
    }
    
    deinit {
        lock.synchronized {
            finished = true
            subscriptions = .init()
        }
    }
}

extension Signal {
    
    public func collect(with collector: SubscriptionCollector) -> Signal {
        let next = SignalForwarder<Value, Value>.init(source: self, collector: collector)
        next.collect(subscribe {
            switch $0 {
            case let .right(token):
                next.broadcast(token)
            case let .left(reason):
                next.finish(reason)
            }
        })
        return next
    }
}

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

extension Signal {
    
    /// Transforms Signal into new Signal instance using provided collector
    /// for keeping subscriptions alive. It will be used for all subscriptions
    /// made on the new Signal instance and propagated for all future Signal
    /// transformations made from the returned new one.
    /// When provided collector becomes deallocated any living signals that used it
    /// will automatically switch to collection new subscriptions internally.
    ///
    /// - Parameter collector: SubscriptionCollector used to collect subscriptions for returned signal.
    /// - Returns: New Signal instance of same type, forwarding all tokens and using provided collector.
    public func collect(with collector: SubscriptionCollector) -> Signal {
        let next = SignalForwarder<Value, Value>.init(source: self, collector: collector)
        forward(to: next)
        return next
    }
}

/// SubscriptionCollector is an object keeping subscriptions
/// (transformations and handlers) alive.
/// It can be used to collect subscriptions in Signal chains
/// to control life cycle of those.
/// When SubscriptionCollector becomes deallocated, all managed (collected)
/// subscriptions are released and deleted automatically.
/// This will deallocate all transformed Signal instances using
/// this collector that are not referenced and kept alive intentionally.
public final class SubscriptionCollector {
    private let lock: RecursiveLock = .init()
    private var subscriptions: [Subscription] = .init()

    internal var isActive: Bool = true

    /// Creates empty collector instance.
    public init() {}

    internal func collect(_ subscription: Subscription) {
        lock.synchronized {
            guard isActive else { return }
            subscriptions.append(subscription)
        }
    }

    deinit {
        lock.synchronized {
            isActive = false
            subscriptions = .init()
        }
    }
}
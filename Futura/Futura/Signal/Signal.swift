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

/// Signal is an object that can be used to pass, transform and observe
/// continous stream of values and/or errors generated by some source.
/// Using handlers and transformations allows to easily manipulate
/// and inspect flow of data. Signal also allows to manage execution
/// by selecting threads manually if needed.
/// It does not use any cache or initial value mechanism so all tokens
/// passed before observation will never occour.
public class Signal<Value> {
    internal typealias Token = Result<Value>

    private var subscriptionID: Subscription.ID = 0
    private let privateCollector: SubscriptionCollector = .init()

    #if FUTURA_DEBUG
        internal var debugMode: DebugMode
    #endif
    internal let mtx: Mutex.Pointer = Mutex.make(recursive: true)
    internal var subscribers: [(id: Subscription.ID, subscriber: Subscriber<Value>)] = .init()
    internal weak var collector: SubscriptionCollector?
    internal var finish: Error??
    internal var isFinished: Bool {
        Mutex.lock(mtx)
        defer { Mutex.unlock(mtx) }
        if case .some = finish {
            return true
        } else {
            return false
        }
    }

    #if FUTURA_DEBUG
        internal init(collector: SubscriptionCollector?, debug: DebugMode = .disabled) {
            self.debugMode = debug
            self.collector = collector
        }
    #else
        internal init(collector: SubscriptionCollector?) {
            self.collector = collector
        }
    #endif

    internal func subscribe(_ body: @escaping (Event) -> Void) -> Subscription? {
        Mutex.lock(mtx)
        defer { Mutex.unlock(mtx) }
        guard !isFinished else { return nil }
        let id = subscriptionID.next()
        let subscriber: Subscriber<Value> = .init(body: body)
        let subscription: Subscription = .init(deactivation: { [weak subscriber] in
            subscriber?.deactivate()
        }, unsubscribtion: { [weak self] in
            guard let self = self else { return }
            Mutex.lock(self.mtx)
            defer { Mutex.unlock(self.mtx) }
            if let idx = self.subscribers.firstIndex(where: { $0.id == id }) {
                self.subscribers.remove(at: idx)
            } else { /* do nothing */ }
        })
        subscribers.append((id: id, subscriber: subscriber))
        return subscription
    }

    internal func broadcast(_ token: Token) {
        Mutex.lock(mtx)
        defer { Mutex.unlock(mtx) }
        subscribers.forEach { $0.1.recieve(.token(token)) }
    }

    internal func finish(_ reason: Error? = nil) {
        Mutex.lock(mtx)
        defer { Mutex.unlock(mtx) }
        subscribers.forEach { $0.1.recieve(.finish(reason)) }
        finish = .some(reason)
        let sub = subscribers
        // cache until end of scope to prevent deallocation of subscribers while making changes in subscribers dictionary - prevents crash
        subscribers = .init()
    }

    internal func collect(_ subscribtion: Subscription?) {
        Mutex.lock(mtx)
        defer { Mutex.unlock(mtx) }
        guard let subscribtion = subscribtion else { return }
        if let collector = collector {
            collector.collect(subscribtion)
        } else {
            privateCollector.collect(subscribtion)
        }
    }

    deinit {
        finish()
        Mutex.destroy(mtx)
    }
}

extension Signal {
    internal enum Event {
        case token(Token)
        case finish(Error?)
    }
}


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

public extension Signal {
    /// Transforms Signal into new Signal instance using provided Worker.
    /// Given Worker will be used to execute all subscriptions made
    /// on new Signal instance.
    /// It will be used without propagation for all subsequent transformations
    /// and and handlers in chain until next switch call.
    ///
    /// - Parameter worker: Worker that will be used to execute
    /// transformations and handlers of new Signal.
    /// - Returns: New Signal instance operating on provided Worker.
    func `switch`(to worker: Worker) -> Signal<Value> {
        let next: SignalScheduler = .init(source: self, worker: worker)
        #if FUTURA_DEBUG
            self.debugLog("+switch -> \(next.debugDescription)")
        #endif
        return next
    }
}

internal final class SignalScheduler<Value>: SignalForwarder<Value, Value> {
    private let associatedWorker: Worker

    internal init(source: Signal<Value>, worker: Worker) {
        self.associatedWorker = worker
        super.init(source: source, collector: source.collector)
        #if FUTURA_DEBUG
            self.collect(source.subscribe({ [weak source] event in
                switch event {
                    case let .token(token):
                        self.broadcast(token)
                    case let .finish(reason):
                        self.finish(reason)
                }
                source?.debugLog("switch() -> \(self.debugDescription)")
            }))
        #else
            source.forward(to: self)
        #endif
    }

    internal override func broadcast(_ token: Token) {
        Mutex.lock(mtx)
        defer { Mutex.unlock(mtx) }
        associatedWorker.schedule {
            self.subscribers.forEach { $0.1.recieve(.token(token)) }
        }
    }

    internal override func finish(_ reason: Error? = nil) {
        Mutex.lock(mtx)
        defer { Mutex.unlock(mtx) }
        associatedWorker.schedule {
            self.subscribers.forEach { $0.1.recieve(.finish(reason)) }
            self.finish = .some(reason)
            let sub = self.subscribers
            // cache until end of scope to prevent deallocation of subscribers while making changes in subscribers dictionary - prevents crash
            self.subscribers = .init()
        }
    }
}

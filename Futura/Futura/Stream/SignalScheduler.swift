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
    func `switch`(to worker: Worker) -> Signal<Value> {
        return SignalScheduler(source: self, worker: worker)
    }
}

internal final class SignalScheduler<Value>: SignalForwarder<Value, Value> {
    private let associatedWorker: Worker

    internal init(source: Signal<Value>, worker: Worker) {
        self.associatedWorker = worker
        super.init(source: source, collector: source.collector)
        source.forward(to: self)
    }

    internal override func broadcast(_ token: Token) {
        lock.synchronized {
            guard !isSuspended else { return }
            let subscribers = self.subscribers
            associatedWorker.schedule {
                subscribers.forEach { $0.1(.right(token)) }
            }
        }
    }

    internal override func finish(_ reason: Error? = nil) {
        lock.synchronized {
            guard !isSuspended else { return } // TODO: this suspended may prevent braodcasting finish - to check
            let subscribers = self.subscribers
            associatedWorker.schedule {
                subscribers.forEach { $0.1(.left(reason)) }
            }
            isFinished = true
            var sub = subscribers
            // cache until end of scope to prevent deallocation of subscribers while making changes in subscribers dictionary - prevents crash
            self.subscribers = .init()
            sub.removeAll() // TODO: to check performance
        }
    }
}

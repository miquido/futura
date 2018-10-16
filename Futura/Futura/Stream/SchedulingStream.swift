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

public extension Stream {
    
    /// Starting at this point all transformations and observations
    /// will be executed by provided Worker until next switch call.
    /// Returns new instance of stream.
    func `switch`(to worker: Worker) -> Stream<Value> {
        return SchedulingStream.init(source: self, worker: worker)
    }
}

internal final class SchedulingStream<Value> : ForwardingStream<Value, Value> {
    
    private let associatedWorker: Worker
    
    internal init(source: Stream<Value>, worker: Worker) {
        self.associatedWorker = worker
        super.init(source: source, collector: source.collector)
        collect(source.subscribe(broadcast))
    }
    
    internal override func broadcast(_ event: Event) {
        lock.synchronized {
            guard !self.isSuspended else { return }
            let subscribers = self.subscribers
            associatedWorker.schedule {
                subscribers.forEach { $0.1(event) }
            }
            cleanupIfNeeded(after: event)
        }
    }
}

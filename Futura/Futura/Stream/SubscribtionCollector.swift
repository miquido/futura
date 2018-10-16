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

public final class SubscribtionCollector {
    private let lock: Lock = .init()
    private var subscribtions: [Subscription] = []
    private var allowNew: Bool = true
    
    public init() {}
    
    internal func collect(_ subscribtion: Subscription) {
        lock.synchronized {
            guard allowNew else { return }
            subscribtions.append(subscribtion)
        }
    }
    
    deinit {
        lock.synchronized {
            allowNew = false
        }
        // TODO: adding subscription while on deinit may cause crash - to check
    }
}

extension Stream {
    
    public func collect(on collector: SubscribtionCollector) -> Stream {
        let next = Stream.init(collector: collector)
        next.collect(self.subscribe {
            next.broadcast($0)
        })
        return next
    }
}

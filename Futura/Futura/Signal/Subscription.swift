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

internal final class Subscription {
    internal typealias ID = UInt64
    
    private let unsubscribe: () -> Void
    internal let deactivate: () -> Void
    
    internal init(deactivation: @escaping () -> Void, unsubscribtion: @escaping () -> Void) {
        self.deactivate = deactivation
        self.unsubscribe = unsubscribtion
    }
    
    deinit {
        unsubscribe()
    }
}

internal final class Subscriber<Value> {
    internal typealias Event = Signal<Value>.Event
    private let body: (Event) -> Void
    internal var isActive: Bool = true
    
    internal init(body: @escaping (Event) -> Void) {
        self.body = body
    }
    
    internal func forward(_ event: Event) {
        guard isActive else { return }
        body(event)
    }
}

extension Subscription.ID {
    internal mutating func next() -> Subscription.ID {
        defer { self += 1 }
        return self
    }
}

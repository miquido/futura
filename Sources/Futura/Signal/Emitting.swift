/* Copyright 2020 Miquido

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

/// Emitting is a Signal property wrapper that broadcasts value changes..
@propertyWrapper
public final class Emitting<Wrapped>: Signal<Wrapped> {
    
    /// - Parameter wrappedValue: initial property value
    public init(wrappedValue: Wrapped) {
        self.wrappedValue = wrappedValue
        super.init(collector: nil)
    }

    /// Access to wrapped value.
    /// Mutations will be broadcasted through signal..
    public var wrappedValue: Wrapped {
        didSet {
            self.broadcast(.success(wrappedValue))
        }
    }
    
    /// Read only reference to this Emitting as Signal.
    public var signal: Signal<Wrapped> {
        return self
    }
}

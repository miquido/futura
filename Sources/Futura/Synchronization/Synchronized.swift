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

/// Property wrapper for synchronized access.
/// Synchronization provided by recursive mutex.
/// It should not be used to synchronize threads from multiple processes.
@propertyWrapper
public final class Synchronized<Wrapped> {
    
    private let mtx: Mutex.Pointer = Mutex.make(recursive: true)
    private var _wrappedValue: Wrapped
    
    /// - Parameter wrappedValue: initial property value
    public init(wrappedValue: Wrapped) {
        self._wrappedValue = wrappedValue
    }

    deinit {
        Mutex.destroy(mtx)
    }

    /// Synchronized access to wrapped value
    public var wrappedValue: Wrapped {
        get {
            Mutex.lock(mtx)
            defer { Mutex.unlock(mtx) }
            return _wrappedValue
        }
        set {
            Mutex.lock(mtx)
            defer { Mutex.unlock(mtx) }
           _wrappedValue = newValue
        }
    }
    
    public func synchronized<T>(_ access: (inout Wrapped) throws -> T) rethrows -> T {
        Mutex.lock(mtx)
        defer { Mutex.unlock(mtx) }
        return try access(&_wrappedValue)
    }
}

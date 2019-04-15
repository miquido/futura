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

import libkern

public enum AtomicFlag {
    
    /// atomic_flag pointer type
    public typealias Pointer = UnsafeMutablePointer<atomic_flag>
    
    ///
    /// - Returns: Pointer to new ataomic flag instance
    @inline(__always)
    public static func make() -> Pointer {
        let pointer = Pointer.allocate(capacity: 1)
        pointer.pointee = atomic_flag()
        return pointer
    }
    
     /// - Parameter pointer: Pointer to flag to be destroyed.
    @inline(__always)
    public static func destroy(_ pointer: Pointer) {
        pointer.deinitialize(count: 1)
        pointer.deallocate()
    }
    
    /// Reads current value of flag and sets it to true
    ///
    /// - Parameter pointer: Pointer to flag to be read and set.
    @discardableResult @inline(__always)
    public static func readAndSet(_ pointer: Pointer) -> Bool {
        return atomic_flag_test_and_set(pointer)
    }
    
    /// Clears flag (set to false)
    ///
     /// - Parameter pointer: Pointer to flag to be cleared.
    @inline(__always)
    public static func clear(_ pointer: Pointer) {
        atomic_flag_clear(pointer)
    }
}

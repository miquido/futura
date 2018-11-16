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

import Darwin.POSIX

#warning("to complete docs")
/// pthread_mutex api wrapper
public enum Mutex {
    
    #warning("to complete docs")
    /// pthread_mutex_t pointer type
    public typealias Pointer = UnsafeMutablePointer<pthread_mutex_t>
    
    #warning("to complete docs")
    /// Creates new instance of pthread_mutex
    @inline(__always)
    public static func make(recursive: Bool) -> Pointer {
        let pointer = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
        let attr = UnsafeMutablePointer<pthread_mutexattr_t>.allocate(capacity: 1)
        guard pthread_mutexattr_init(attr) == 0 else { preconditionFailure() }
        pthread_mutexattr_settype(attr, recursive ? PTHREAD_MUTEX_RECURSIVE : PTHREAD_MUTEX_NORMAL)
        pthread_mutexattr_setpshared(attr, PTHREAD_PROCESS_PRIVATE)
        guard pthread_mutex_init(pointer, attr) == 0 else { preconditionFailure() }
        pthread_mutexattr_destroy(attr)
        attr.deinitialize(count: 1)
        attr.deallocate()
        return pointer
    }
    
    #warning("to complete docs")
    /// Deallocates instance of pthread_mutex
    @inline(__always)
    public static func destroy(_ pointer: Pointer) {
        pthread_mutex_destroy(pointer)
        pointer.deinitialize(count: 1)
        pointer.deallocate()
    }
    
    #warning("to complete docs")
    /// Locks on instance of pthread_mutex
    @inline(__always)
    public static func lock(_ pointer: Pointer) {
        pthread_mutex_lock(pointer)
    }
    
    #warning("to complete docs")
    /// Tries to lock on instance of pthread_mutex
    @inline(__always)
    public static func tryLock(_ pointer: Pointer) -> Bool {
        return pthread_mutex_trylock(pointer) == 0
    }
    
    #warning("to complete docs")
    /// Unlocks on instance of pthread_mutex
    @inline(__always)
    public static func unlock(_ pointer: Pointer) {
        pthread_mutex_unlock(pointer)
    }
}

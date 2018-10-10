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

import Darwin

internal enum ThreadCond {
    
    internal static func make() -> UnsafeMutablePointer<_opaque_pthread_cond_t> {
        let pointer = UnsafeMutablePointer<_opaque_pthread_cond_t>.allocate(capacity: 1)
        let condattr = UnsafeMutablePointer<pthread_condattr_t>.allocate(capacity: 1)
        guard pthread_condattr_init(condattr) == 0 else { preconditionFailure() }
        pthread_cond_init(pointer, condattr)
        return pointer
    }
    
    internal static func destroy(_ pointer: UnsafeMutablePointer<_opaque_pthread_cond_t>) {
        pthread_cond_destroy(pointer)
        pointer.deinitialize(count: 1)
        pointer.deallocate()
    }
    
    @inline(__always)
    internal static func wait(_ pointer: UnsafeMutablePointer<_opaque_pthread_cond_t>, with mutex: UnsafeMutablePointer<pthread_mutex_t>) {
        pthread_cond_wait(pointer, mutex)
    }
    
    @inline(__always)
    internal static func signal(_ pointer: UnsafeMutablePointer<_opaque_pthread_cond_t>) {
        pthread_cond_signal(pointer)
    }
}

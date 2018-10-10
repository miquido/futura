//
//  Mutex.swift
//  Futura
//
//  Created by Kacper Kaliński on 10/10/2018.
//  Copyright © 2018 Miquido. All rights reserved.
//

import Darwin

internal enum Mutex {
    
    internal static func make(recursive: Bool) -> UnsafeMutablePointer<pthread_mutex_t> {
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
    
    internal static func destroy(_ pointer: UnsafeMutablePointer<pthread_mutex_t>) {
        pthread_mutex_destroy(pointer)
        pointer.deinitialize(count: 1)
        pointer.deallocate()
    }
    
    @inline(__always)
    internal static func lock(_ pointer: UnsafeMutablePointer<pthread_mutex_t>) {
        pthread_mutex_lock(pointer)
    }
    
    @inline(__always)
    internal static func tryLock(_ pointer: UnsafeMutablePointer<pthread_mutex_t>) -> Bool {
        return pthread_mutex_trylock(pointer) == 0
    }
    
    @inline(__always)
    internal static func unlock(_ pointer: UnsafeMutablePointer<pthread_mutex_t>) {
        pthread_mutex_unlock(pointer)
    }
}

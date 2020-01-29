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

#if os(Linux)
import Glibc
#else
import Darwin.POSIX
#endif

#if os(Linux)
@usableFromInline
fileprivate let n_sec_in_m_sec: __time_t = 1_000_000 // nanoseconds in milisecond
@usableFromInline
fileprivate let n_sec_in_sec: __time_t = 1_000 * n_sec_in_m_sec // nanoseconds in second
#else
@usableFromInline
internal let n_sec_in_m_sec: __darwin_time_t = 1_000_000 // nanoseconds in milisecond
@usableFromInline
internal let n_sec_in_sec: __darwin_time_t = 1_000 * n_sec_in_m_sec // nanoseconds in second
#endif

/// pthread_mutex api wrapper
public enum Mutex {
    /// Error thrown on mutex timeout
    public struct Timeout: Error {
        @usableFromInline
        internal init(){}
    }
    
    /// pthread_mutex_t pointer type
    public typealias Pointer = UnsafeMutablePointer<pthread_mutex_t>

    /// Creates new instance of pthread_mutex.
    /// It is not automatically managed by ARC. You are responsible
    /// to deallocate it manually by calling destroy function.
    ///
    /// - Parameter recursive: Tells if created mutex should be recursive or not.
    /// - Returns: Pointer to new mutex instance
    @inlinable
    public static func make(recursive: Bool) -> Pointer {
        let pointer: UnsafeMutablePointer<pthread_mutex_t> = .allocate(capacity: 1)
        let attr: UnsafeMutablePointer<pthread_mutexattr_t> = .allocate(capacity: 1)
        guard pthread_mutexattr_init(attr) == 0 else { preconditionFailure() }
        pthread_mutexattr_settype(attr, recursive ? PTHREAD_MUTEX_RECURSIVE : PTHREAD_MUTEX_NORMAL)
        pthread_mutexattr_setpshared(attr, PTHREAD_PROCESS_PRIVATE)
        guard pthread_mutex_init(pointer, attr) == 0 else { preconditionFailure() }
        pthread_mutexattr_destroy(attr)
        attr.deinitialize(count: 1)
        attr.deallocate()
        return pointer
    }

    /// Deallocates instance of pthread_mutex
    ///
    /// - Parameter pointer: Pointer to mutex to be destroyed.
    @inlinable
    public static func destroy(_ pointer: Pointer) {
        pthread_mutex_destroy(pointer)
        pointer.deinitialize(count: 1)
        pointer.deallocate()
    }

    /// Locks on instance of pthread_mutex or waits until unlocked if locked.
    ///
    /// - Parameter pointer: Pointer to mutex to be locked.
    @inlinable
    public static func lock(_ pointer: Pointer) {
        pthread_mutex_lock(pointer)
    }
    
    /// Locks on instance of pthread_mutex or waits until unlocked if locked.
    /// Throws an error if time condition was not met
    ///
    /// - Parameter pointer: Pointer to mutex to be locked.
    /// - Parameter timeout: Lock wait timeout in seconds.
    @inlinable
    public static func lock(_ pointer: Pointer, timeout: UInt8) throws -> Void {
        #if os(Linux)
        var currentTimeout = __time_t(timeout) * mSecSec
        #else
        var timeoutTimeLeft = __darwin_time_t(timeout) * n_sec_in_sec
        #endif
        
        var remained: timespec = .init()
        var requested: timespec = timespecFrom(miliseconds: 100)
        while timeoutTimeLeft > 0 {
            switch pthread_mutex_trylock(pointer) {
                case 0: // success
                    return
                case EINVAL: // mutex invalid
                    return assertionFailure()
                case EBUSY: // locked
                    sleepLoop: while true {
                        switch nanosleep(&requested, &remained) {
                            case 0: // success
                                break sleepLoop
                            case EINTR: // interupt
                                requested.tv_nsec = remained.tv_nsec
                            case let errorCode: // unexpected
                                fatalError("nanosleep error: \(errorCode)")
                        }
                    }
                    timeoutTimeLeft -= (requested.tv_nsec - remained.tv_nsec)
                    timeoutTimeLeft -= (requested.tv_sec - remained.tv_sec) * n_sec_in_sec
                case let errorCode: // unexpected
                    fatalError("mutex error: \(errorCode)")
            }
        }
        throw Timeout()
//        var rem = timespec(tv_sec: 0, tv_nsec: 0)
//        var req = timespec(tv_sec: 0, tv_nsec: 0)
//        while pthread_mutex_trylock(pointer) != 0 {
//            if currentTimeout <= 0 {
//                throw Timeout()
//            } else { /* continue waiting */ }
//            let requested = currentTimeout < nSecMsec ? currentTimeout : nSecMsec
//            req.tv_nsec = requested
//            while nanosleep(&req, &rem) == EINTR {
//                req.tv_nsec = rem.tv_nsec
//            }
//            currentTimeout -= (requested - rem.tv_nsec)
//        }
    }
    
    @inlinable
    internal static func timespecFrom(miliseconds: UInt) -> timespec {
        return .init(
            tv_sec: __darwin_time_t(miliseconds / 1000),
            tv_nsec: Int(miliseconds % 1000) * n_sec_in_m_sec
        )
    }

    /// Tries to lock on instance of pthread_mutex. Locks if unlocked or passes if locked.
    ///
    /// - Parameter pointer: Pointer to mutex to be locked.
    /// - Returns: Result of trying to lock. True if succeeded, false otherwise.
    @inlinable
    public static func tryLock(_ pointer: Pointer) -> Bool {
        return pthread_mutex_trylock(pointer) == 0
    }

    /// Unlocks on instance of pthread_mutex
    ///
    /// - Parameter pointer: Pointer to mutex to be unlocked.
    @inlinable
    public static func unlock(_ pointer: Pointer) {
        pthread_mutex_unlock(pointer)
    }
}

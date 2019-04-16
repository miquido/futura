/* Copyright 2019 Miquido

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License. */

import Futura

/// TestWorker is designed to make synchronous unit tests
/// while using asynchronous constructs like Future.
/// You can swap your workers to TestWorker to take control
/// when exactly each scheduled task will be executed.
/// Note here that if you use this worker you will not be
/// able to find and test rare bugs caused by specific thread
/// execution paths in paralell.
public final class TestWorker: Worker {
    private let lock: RecursiveLock = .init()
    private var scheduled: [() -> Void] = []
    
    /// Just makes empty instance of TestWorker
    public init() {}

    /// Worker protocol requirement, it will store tasks
    /// in array and keep its order when executing.
    /// Scheduled tasks will never be executed automatically.
    /// If you wish to execute any scheduled task you have
    /// to do it manually.
    public func schedule(_ work: @escaping () -> Void) {
        lock.synchronized {
            scheduled.append(work)
        }
    }

    /// Executes next scheduled task if any.
    ///
    /// - Returns: true if any task was executed, false otherwise
    @discardableResult
    public func executeNext() -> Bool {
        return lock.synchronized {
            guard scheduled.count > 0 else { return false }
            scheduled.removeFirst()()
            return true
        }
    }

    /// Executes all scheduled tasks. If any of tasks
    /// schedules new tasks to this worker it will be
    /// also exeucuted in this loop.
    ///
    /// - Returns: count of executed tasks
    @discardableResult
    public func execute() -> Int {
        return lock.synchronized {
            var count: Int = 0
            while executeNext() { count += 1 }
            return count
        }
    }

    /// Current count of scheduled tasks.
    /// Note here that in concurrent environment
    /// it might return value that is incorrect
    /// just after returning it due to used lock
    public var taskCount: Int {
        return lock.synchronized { scheduled.count }
    }

    /// Current state of scheduled tasks
    /// Note here that in concurrent environment
    /// it might return value that is incorrect
    /// just after returning it due to used lock
    public var isEmpty: Bool {
        return lock.synchronized { scheduled.count == 0 }
    }
}

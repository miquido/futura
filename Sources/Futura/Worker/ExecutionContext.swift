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

/// ExecutionContext allows to define Worker associated with given task.
public enum ExecutionContext {
    /// Task will be executed with Worker inherited from it predecessor
    /// or use current thread to execute. It is undefined thich Worker/thread
    /// will execute this task.
    case undefined
    /// Explicitly provided Worker instance will be responisble to execute
    /// given task. Exact execution depends on Worker behaviour thus it is
    /// guaranteed that provided Worker will execute task.
    case explicit(Worker)
}

internal extension ExecutionContext {
    @inlinable
    func execute(_ function: @escaping () -> Void) {
        switch self {
            case .undefined:
                function()
            case let .explicit(worker):
                worker.schedule(function)
        }
    }
}

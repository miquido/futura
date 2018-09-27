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

/// ExecutionContext enables to describe how to execute things
public enum ExecutionContext {
    /// Context will inherit worker used to call it
    case inheritWorker
    /// Context will switch to provided worker as async task
    case async(using: Worker)
}

internal extension ExecutionContext {
    
    @inline(__always)
    func execute(_ function: @escaping () -> Void) {
        switch self {
        case .inheritWorker:
            function()
        case let .async(worker):
            worker.schedule(function)
        }
    }
}

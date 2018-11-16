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

#warning("to complete docs")
/// ExecutionContext enables to describe how to execute things
public enum ExecutionContext {
    #warning("to complete docs")
    /// Context will inherit worker from completing task or use current thread
    case undefined
    #warning("to complete docs")
    /// Context will switch to provided worker or continue if already on it
    case explicit(Worker)
}

internal extension ExecutionContext {
    
    @inline(__always)
    func execute(_ function: @escaping () -> Void) {
        switch self {
        case .undefined:
            function()
        case let .explicit(worker):
            worker.schedule(function)
        }
    }
}

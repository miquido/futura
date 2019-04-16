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

#if FUTURA_DEBUG
/// Debug mode used to held debugging Futura.
public enum DebugMode {
    /// No logs used
    case disabled
    /// Logs only for selected instance
    case single
    /// Logs for selected instance and all its successors
    case propagated
}

internal extension DebugMode {
    var isEnabled: Bool {
        switch self {
        case .disabled:
            return false
        case .single:
            return true
        case .propagated:
            return true
        }
    }
    
    var propagated: DebugMode {
        switch self {
        case .disabled:
            return .disabled
        case .single:
            return .disabled
        case .propagated:
            return .propagated
        }
    }
    
    func combined(with other: DebugMode) -> DebugMode {
        switch (self, other) {
        case (_, .propagated), (.propagated, _):
            return .propagated
        case _:
            return .disabled
        }
    }
}
#endif

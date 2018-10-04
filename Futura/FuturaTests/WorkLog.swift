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

final class WorkLog : Equatable {

    private var log: [Event]
    
    enum Event {
        case then(String)
        case fail(String)
        case resulted
        case always
        case recover
        case `catch`
        case map
        case flatMap
        case `switch`
    }

    init(_ elements: WorkLog.Event...) {
        self.log = Array(elements)
    }
    
    init(_ elements: [WorkLog.Event]) {
        self.log = Array(elements)
    }
    
    func log(_ event: Event) {
        log.append(event)
    }
    
    var isEmpty: Bool {
        return log.isEmpty
    }
    
    static func == (lhs: WorkLog, rhs: WorkLog) -> Bool {
        return lhs.log == rhs.log
    }
}

extension WorkLog.Event : CustomStringConvertible {
    var description: String {
        return debugDescription
    }
}

extension WorkLog.Event : CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case let .then(value):
            return "then(\(value))"
        case let .fail(error):
            return "fail(\(error))"
        case .resulted:
            return "resulted"
        case .always:
            return "always"
        case .recover:
            return "recover"
        case .catch:
            return "catch"
        case .map:
            return "map"
        case .flatMap:
            return "flatMap"
        case .switch:
            return "switch"
        }
    }
}

extension WorkLog.Event : Equatable {
    static func == (lhs: WorkLog.Event, rhs: WorkLog.Event) -> Bool {
        return lhs.debugDescription == rhs.debugDescription
    }
}

extension WorkLog : CustomStringConvertible {
    var description: String {
        return debugDescription
    }
}

extension WorkLog : CustomDebugStringConvertible {
    var debugDescription: String {
        return "WorkLog[\(log.map { $0.debugDescription }.joined(separator: "-"))]"
    }
}

extension WorkLog : ExpressibleByArrayLiteral {
    convenience init(arrayLiteral elements: WorkLog.Event...) {
        self.init(elements)
    }
}

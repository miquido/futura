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

import Futura

extension Future {
    @discardableResult
    func logResults(with workLog: FutureWorkLog) -> Self {
        self
            .value { value in
                workLog.log(.value(testDescription(of: value)))
            }
            .error { reason in
                workLog.log(.error(testDescription(of: reason)))
            }
            .resulted {
                workLog.log(.resulted)
            }
            .always {
                workLog.log(.always)
        }
        return self
    }
}

final class FutureWorkLog: Equatable {
    private var log: [Event]

    enum Event {
        case value(String)
        case error(String)
        case resulted
        case always
        case recover
        case `catch`
        case map
        case flatMap
        case `switch`
    }

    init(_ elements: FutureWorkLog.Event...) {
        self.log = Array(elements)
    }

    init(_ elements: [FutureWorkLog.Event]) {
        self.log = Array(elements)
    }

    func log(_ event: Event) {
        log.append(event)
    }

    var isEmpty: Bool {
        return log.isEmpty
    }

    static func == (lhs: FutureWorkLog, rhs: FutureWorkLog) -> Bool {
        return lhs.log == rhs.log
    }
}

extension FutureWorkLog.Event: CustomStringConvertible {
    var description: String {
        return debugDescription
    }
}

extension FutureWorkLog.Event: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
            case let .value(value):
                return "value(\(value))"
            case let .error(error):
                return "error(\(error))"
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

extension FutureWorkLog.Event: Equatable {
    static func == (lhs: FutureWorkLog.Event, rhs: FutureWorkLog.Event) -> Bool {
        return lhs.debugDescription == rhs.debugDescription
    }
}

extension FutureWorkLog: CustomStringConvertible {
    var description: String {
        return debugDescription
    }
}

extension FutureWorkLog: CustomDebugStringConvertible {
    var debugDescription: String {
        return "WorkLog[\(log.map { $0.debugDescription }.joined(separator: "-"))]"
    }
}

extension FutureWorkLog: ExpressibleByArrayLiteral {
    convenience init(arrayLiteral elements: FutureWorkLog.Event...) {
        self.init(elements)
    }
}

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

final class StreamWorkLog: Equatable {
    private var log: [Event]

    enum Event {
        case values(String)
        case failures(String)
        case ended
        case terminated(String)
        case finished
        case map
        case flatMap
        case filter(Bool)
    }

    init(_ elements: StreamWorkLog.Event...) {
        self.log = Array(elements)
    }

    init(_ elements: [StreamWorkLog.Event]) {
        self.log = Array(elements)
    }

    func log(_ event: Event) {
        log.append(event)
    }

    var isEmpty: Bool {
        return log.isEmpty
    }

    static func == (lhs: StreamWorkLog, rhs: StreamWorkLog) -> Bool {
        return lhs.log == rhs.log
    }
}

extension StreamWorkLog.Event: CustomStringConvertible {
    var description: String {
        return debugDescription
    }
}

extension StreamWorkLog.Event: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
            case let .values(value):
                return "values(\(value))"
            case let .failures(error):
                return "failures(\(error))"
            case .map:
                return "map"
            case .flatMap:
                return "flatMap"
            case .ended:
                return "ended"
            case .finished:
                return "finished"
            case let .terminated(error):
                return "terminated(\(error))"
            case let .filter(isIncluded):
                return "filter(\(isIncluded))"
        }
    }
}

extension StreamWorkLog.Event: Equatable {
    static func == (lhs: StreamWorkLog.Event, rhs: StreamWorkLog.Event) -> Bool {
        return lhs.debugDescription == rhs.debugDescription
    }
}

extension StreamWorkLog: CustomStringConvertible {
    var description: String {
        return debugDescription
    }
}

extension StreamWorkLog: CustomDebugStringConvertible {
    var debugDescription: String {
        return "StreamWorkLog[\(log.map { $0.debugDescription }.joined(separator: "-"))]"
    }
}

extension StreamWorkLog: ExpressibleByArrayLiteral {
    convenience init(arrayLiteral elements: StreamWorkLog.Event...) {
        self.init(elements)
    }
}

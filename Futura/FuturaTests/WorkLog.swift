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

final class WorkLog : Equatable {
    
    var log: [Event]
    
    var result: Int?
    var reason: Error?
    
    enum Event : String {
        case then
        case fail
        case resulted
        case always
        case recover
        case `catch`
        case map
        case flatMap
        case clone
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
    
    static func == (lhs: WorkLog, rhs: WorkLog) -> Bool {
        return lhs.log == rhs.log
    }
    
    var isEmpty: Bool {
        return log.isEmpty
    }
    
    func bind(future: Future<Int>) {
        future
            .then { value in
                self.log(.then)
                self.result = value
            }
            .fail { reason in
                self.log(.fail)
                self.reason = reason
            }
            .resulted {
                self.log(.resulted)
            }
            .always {
                self.log(.always)
            }
    }
}

extension WorkLog : CustomStringConvertible {
    var description: String {
        return "[\(log.map { $0.rawValue }.joined(separator: "-"))]"
    }
}

extension WorkLog : CustomDebugStringConvertible {
    var debugDescription: String {
        return "[\(log.map { $0.rawValue }.joined(separator: "-"))]"
    }
}

extension WorkLog : ExpressibleByArrayLiteral {
    convenience init(arrayLiteral elements: WorkLog.Event...) {
        self.init(elements)
    }
}

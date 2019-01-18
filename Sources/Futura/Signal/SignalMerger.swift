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

/// Merges Signals into new Signal that will emit whenever one of merged Signals emit.
/// When any of merged Signals becomes finished merged Signal also becomes finished.
///
/// - Warning: Result signal will not inherit collector from any of provided Signals.
///
/// - Parameter signals: Signals to merge
/// - Returns: New Signal instance merging provided Signals
public func merge<Value>(_ signals: Signal<Value>...) -> Signal<Value> {
    let mergedSignal: Signal<Value> = .init(collector: nil)
    signals.forEach { signal in
        mergedSignal.collect(signal.subscribe({ event in
            switch event {
                case let .token(token):
                    mergedSignal.broadcast(token)
                case let .finish(reason):
                    mergedSignal.finish(reason)
            }
        }))
    }
    return mergedSignal
}

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

/// Receiver is a Signal that allows plugging in other signals..
/// It can be used as input for signal based APIs i.e. for UI bindings.
public final class Receiver<Value>: Signal<Value> {
    private var connectedCollector: SubscriptionCollector = .init()
    
    /// Creates Receiver instance with given type.
    public init() {
        super.init(collector: nil)
    }

    /// Sets provided signal as input for this receiver.
    /// When connected signal finishes it will be disconnected,
    /// finishing will not be propagated. It will be automatically disconnected on deinit.
    ///
    /// - Warning: It will replace previously connected signal if any.
    ///
    /// - Warning: Receiver does not propagate finishing of connected signals.
    /// When connected signal finishes it will be disconnected.
    /// Receiver will automatically become ended on deinit.
    ///
    /// - Warning: Receiver will not be kept in memory by connected signal.
    /// You have to keep reference to it manually. It will be automatically disconnected on deinit.
    ///
    /// - Parameter signal: Signal to be connected.
    public func connect(_ signal: Signal<Value>) {
        disconnect()
        guard let sub = (signal.subscribe { [weak self] event in
            switch event {
                case let .token(token):
                    self?.broadcast(token)
                case .finish:
                    self?.disconnect()
            }
        }) else { return }
        connectedCollector.collect(sub)
    }
    
    /// Removes previously connected signal if any.
    public func disconnect() {
        connectedCollector.deactivate()
        connectedCollector = .init()
    }

    /// Read to this Receiver as Signal.
    public var signal: Signal<Value> {
        return self
    }
}

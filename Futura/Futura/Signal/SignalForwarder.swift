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

internal class SignalForwarder<V1, V2>: Signal<V2> {
    fileprivate weak var source: Signal<V1>?

    internal init(source: Signal<V1>, collector: SubscriptionCollector?) {
        self.source = source
        #if FUTURA_DEBUG
        super.init(collector: collector, debug: source.debugMode.propagated)
        #else
        super.init(collector: collector)
        #endif
    }
}

extension Signal {
    internal func forward(to destination: SignalForwarder<Value, Value>) {
        precondition(destination.source === self)
        destination.collect(subscribe({ event in
            switch event {
                case let .token(token):
                    destination.broadcast(token)
                case let .finish(reason):
                    destination.finish(reason)
            }
        }))
    }
}

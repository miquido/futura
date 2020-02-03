/* Copyright 2020 Miquido

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

public extension Signal {
    /// Transforms Signal into new Signal instance with token buffer.
    /// Repeats all buffered tokens on new subscriptions.
    ///
    /// - Warning: Buffer will not be propagated. Tokens will be reemitted only
    /// after subscribing directly to buffered signal instance. If you like to make buffer part of
    /// API use this transformation as last in chain to preserve buffer behaviour.
    ///
    /// - Warning: When connecting to buffered signal you have to prebuild handlers chain before subscribing
    /// to buffered signal. Otherwise only first handler/transformation in chain will receive buffered values.
    ///
    /// - Warning: Buffer will be applied on new subscriptions on undefined thread.
    /// In most cases it will be same thread on which subscriptions are added.
    ///
    /// - Parameter size: Size of the buffer
    /// - Returns: New Signal instance which repeats buffered tokens on new subscriptions.
    func buffer(_ size: Int = 1) -> Signal<Value> {
        let next: SignalBuffer = .init(source: self, size: size)
        #if FUTURA_DEBUG
        next.debugMode = self.debugMode.propagated
        self.debugLog("+buffer(\(size)) -> \(next.debugDescription)")
        #endif
        return next
    }
}

internal final class SignalBuffer<Value>: SignalForwarder<Value, Value> {
    fileprivate let bufferSize: Int
    fileprivate var buffer: Array<Token>

    internal init(source: Signal<Value>, size: Int) {
        assert(size > 0, "Cannot make empty buffers")
        bufferSize = size
        buffer = .init()
        buffer.reserveCapacity(size)
        super.init(source: source, collector: source.collector)
        collect(source.subscribe { event in
            switch event {
                case let .token(token):
                    self.buffer(token)
                    self.broadcast(token)
                case let .finish(reason):
                    self.finish(reason)
            }
        })
    }
    
    fileprivate func buffer(_ token: Token) {
        if buffer.count < bufferSize {
            buffer.append(token)
        } else {
            _ = buffer.removeFirst()
            buffer.append(token)
        }
    }
    
    override func subscribe(_ body: @escaping (Signal<Value>.Event) -> Void) -> Subscription? {
        Mutex.lock(mtx)
        defer { Mutex.unlock(mtx) }
        defer { buffer.forEach { body(.token($0)) } }
        return super.subscribe(body)
    }
}

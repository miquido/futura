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

/// Channel allows writing and broadcasting data through streams.
public final class Channel<Value> : Stream<Value> {
    
    public init() {
        super.init(collector: nil)
    }
    
    /// Broadcasts value to all channel's stream observers and children
    public func broadcast(_ value: Value) {
        broadcast(.value(value))
    }
    
     /// Broadcasts error to all channel's stream observers and children
    public func broadcast(_ error: Error) {
        broadcast(.error(error))
    }
    
     /// Closes channel's stream and its children
    public func close() {
        broadcast(.close)
    }
    
    /// Terminates channel's stream and its children.
    /// Termination have similar effect to colosing but allows to pass error
    /// Which caused termination while closing is for just ending stream properly.
    public func terminate(_ reason: Error) {
        broadcast(.terminate(reason))
    }
    
    /// Read only reference (as Stream) of this channel
    public var stream: Stream<Value> {
        return self
    }
}

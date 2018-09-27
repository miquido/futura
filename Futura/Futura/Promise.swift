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

/// Promise is container for future that allows to modify (fulfill or break) result of future
public final class Promise<Value> {
    
    public let future: Future<Value> = Future()
    
    /// Creates promise that can be completed
    public init() {}
    
    /// Creates already completed promise with given result
    public convenience init(with result: Result<Value>) {
        self.init()
        future.become(.resulted(with: result))
    }
    
    /// Completes Promise with value. Will be ignored when already completed or canceled.
    public func fulfill(with value: Value){
        future.become(.resulted(with: .success(value)))
    }
    
    /// Completes Promise with error. Will be ignored when already completed or canceled.
    public func `break`(with error: Error) {
        future.become(.resulted(with: .error(error)))
    }
    
    /// Cancels Promise without error. Will be ignored when already completed or canceled.
    public func cancel() {
        future.cancel()
    }
}

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

/// Promise is container for Future that allows to set outcome of it.
/// It is used to declare result of delayed/async work that will be done
/// in future and fill the result of that action.
/// If Promise was not finished and become deallocated it will automatically
/// cancel contained Future by deallocating it.
public final class Promise<Value> {
    /// Future associated with this Promise instance.
    public let future: Future<Value>

    /// Creates Promise with given context.
    ///
    /// - Parameter executionContext: ExecutionContext that will be used for all
    /// transformations and handlers made on associated Future. Default is .undefined.
    public init(executionContext: ExecutionContext = .undefined) {
        self.future = .init(executionContext: executionContext)
    }

    /// Creates already finished Promise with given value and context.
    ///
    /// - Parameter value: Value finishing this Promise.
    /// - Parameter executionContext: ExecutionContext that will be used for all
    /// transformations and handlers made on associated Future. Default is .undefined.
    public convenience init(succeededWith value: Value, executionContext: ExecutionContext = .undefined) {
        self.init(executionContext: executionContext)
        future.become(.resulted(with: .value(value)))
    }

    /// Creates already finished Promise with given error and context.
    ///
    /// - Parameter error: Error finishing this Promise.
    /// - Parameter executionContext: ExecutionContext that will be used for all
    /// transformations and handlers made on associated Future. Default is .undefined.
    public convenience init(failedWith error: Error, executionContext: ExecutionContext = .undefined) {
        self.init(executionContext: executionContext)
        future.become(.resulted(with: .error(error)))
    }

    /// Finish Promise with given value. It will be ignored when already finished.
    ///
    /// - Parameter value: Value finishing this Promise.
    public func fulfill(with value: Value) {
        future.become(.resulted(with: .value(value)))
    }

    /// Finish Promise with given error. It will be ignored when already finished.
    ///
    /// - Parameter error: Error completing this Promise.
    public func `break`(with error: Error) {
        future.become(.resulted(with: .error(error)))
    }

    /// Finish Promise without value or error. It will be ignored when already finished.
    public func cancel() {
        future.cancel()
    }
}

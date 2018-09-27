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

/// worker using main thread/queue of application
public var mainWorker: Worker = DispatchWorker.main
/// default async worker
public var asyncWorker: Worker = DispatchWorker.default

/// Protocol used to describe worker behaviour. This abstraction allows to use DispatchQueue and other threading solutions for Futures.
public protocol Worker {
    /// Schedule should notify worker to execute given task asynchronously by its own rules without blocking current thread
    func schedule(_ work: @escaping () -> Void) -> Void
}

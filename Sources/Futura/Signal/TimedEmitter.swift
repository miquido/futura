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

import Foundation
import Dispatch

/// TimedEmitter is a Signal that emits in given time intervals.
/// TimedEmitter emits until it becomes ended, terminated or deallocated.
///
/// - Warning: All timed emitter signals comes from background thread (`DispatchQueue.global`).
/// If you need some specific thread to be used please see `switch` function on Signal.
public final class TimedEmitter: Signal<Void> {
    
    private var timer: DispatchSourceTimer
    
    /// Creates TimedEmitter instance with given time interval.
    /// - Warning: New timers are created running and emits signal after first interval.
    ///
    /// - Parameter interval: Time interval in seconds between subsequent signal emits.
    public init(interval: TimeInterval) {
        self.timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
        super.init(collector: nil)
        let dispatchInterval = DispatchTimeInterval.milliseconds(Int(interval * 1000.0))
        timer.schedule(deadline: DispatchTime.now() + dispatchInterval,
                       repeating: dispatchInterval,
                       leeway: dispatchInterval)
        timer.setEventHandler(handler: { [weak self] in
            guard let self = self else { return }
            guard !self.isFinished else { return }
            self.broadcast(.value(Void()))
        })
        timer.resume()
    }
  
    deinit {
        timer.cancel()
    }

    
    /// Finishes this TimedEmitter and all associated Signals.
    /// This method should be called to end TimedEmitter and all associated Signals
    /// without errors when it will not needed to emit values anymore.
    /// It will be called automatically when TimedEmitter becomes deallocated.
    /// This method have no effect on TimedEmitter that have already finished.
    ///
    /// - Note: Finished Signals begins to deallocate if able and releases all
    /// of its subscriptions kept by both its internal collector and external one
    /// if any (it will not affect subscriptions from other signals kept by external collector).
    public func end() {
        finish()
    }
    
    /// Finishes this TimedEmitter and all associated Signals signalling some error.
    /// This method should be called to finish TimedEmitter with eror condition
    /// that makes keeping it alive inaccurate.
    /// This method have no effect on TimedEmitter that have already finished.
    ///
    /// - Note: Finished Signals begins to deallocate if able and releases all
    /// of its subscriptions kept by both its internal collector and external one
    /// if any (it will not affect subscriptions from other signals kept by external collector).
    ///
    /// - Parameter reason: The error that caused termination.
    public func terminate(_ reason: Error) {
        finish(reason)
    }
}

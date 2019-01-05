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

#if FUTURA_DEBUG
    import os.log

    internal let futuraLogger: OSLog = .init(subsystem: "com.miquido.futura", category: "Futura")

    /// Debug configuration of Futura.
    /// You can change values to achieve different debug behavior.
    public enum FuturaDebug {
        /// Logger function used to produce logs. You can change it if you need other output.
        /// - Warning: changing logger is not thread safe operation.
        public static var logger: (String) -> Void = { message in
            os_log("%{public}@", log: futuraLogger, type: .debug, message)
        }
    }
#endif

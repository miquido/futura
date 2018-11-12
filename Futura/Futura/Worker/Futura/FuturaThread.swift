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

import Darwin

internal final class FuturaThread {
    internal typealias Task = () -> Void

    private var pthread: UnsafeMutablePointer<_opaque_pthread_t>
    private let context: Context = .init()

    internal init() {
        AtomicFlag.readAndSet(context.aliveFlag)
        Mutex.unlock(context.threadMutex) // this is wired, but without this unlock it does not run properly... to check

        let attr = UnsafeMutablePointer<pthread_attr_t>.allocate(capacity: 1)
        guard pthread_attr_init(attr) == 0 else { fatalError() }
        pthread_attr_setdetachstate(attr, PTHREAD_CREATE_DETACHED)

        var pthread: UnsafeMutablePointer<_opaque_pthread_t>!
        let res = pthread_create(&pthread, attr, { (pointer) -> UnsafeMutableRawPointer? in
            let context: Context = Unmanaged<Context>.fromOpaque(pointer).takeRetainedValue()
            FuturaThread.run(with: context)
            return nil
        }, Unmanaged.passRetained(context).toOpaque())
        precondition(res == 0, "Unable to create thread: \(res)")

        self.pthread = pthread
    }

    internal func append(task: @escaping Task) {
        context.taskList.append(task)
        ThreadCond.signal(context.cond)
    }

    internal var isCurrent: Bool {
        return pthread_equal(pthread, pthread_self()) != 0
    }

    internal func end() {
        AtomicFlag.clear(context.aliveFlag)
        ThreadCond.signal(context.cond)
    }

    fileprivate static func run(with context: Context) {
        while AtomicFlag.readAndSet(context.aliveFlag) {
            while let task = context.taskList.next() {
                task()
            }
            guard AtomicFlag.readAndSet(context.aliveFlag) else { break }
            ThreadCond.wait(context.cond, with: context.threadMutex)
        }
    }
}

extension FuturaThread {
    fileprivate final class Context {
        fileprivate let threadMutex: UnsafeMutablePointer<pthread_mutex_t> = Mutex.make(recursive: false)
        fileprivate let cond: UnsafeMutablePointer<_opaque_pthread_cond_t> = ThreadCond.make()
        fileprivate var aliveFlag: UnsafeMutablePointer<atomic_flag> = AtomicFlag.make()
        fileprivate let taskList: TaskList = .init()

        fileprivate init() {}

        deinit {
            Mutex.destroy(threadMutex)
            ThreadCond.destroy(cond)
            AtomicFlag.destroy(aliveFlag)
        }
    }
}

extension FuturaThread {
    fileprivate final class TaskList {
        private let mtx = Mutex.make(recursive: false)
        private var nextItem: Item?
        private var lastItem: Item?

        deinit {
            Mutex.destroy(mtx)
        }

        fileprivate func append(_ task: @escaping Task) {
            Mutex.lock(mtx)
            defer { Mutex.unlock(mtx) }

            let item: Item = .init(task: task)

            if let lastItem = lastItem {
                lastItem.next = item
            } else {
                self.nextItem = item
            }
            self.lastItem = item
        }

        fileprivate func next() -> Task? {
            Mutex.lock(mtx)
            defer { Mutex.unlock(mtx) }

            guard let nextItem = nextItem else {
                return nil
            }

            if let item = nextItem.next {
                self.nextItem = item
            } else {
                self.nextItem = nil
                self.lastItem = nil
            }
            return nextItem.task
        }
    }
}

extension FuturaThread.TaskList {
    fileprivate final class Item {
        fileprivate let task: FuturaThread.Task
        fileprivate var next: Item?

        fileprivate init(task: @escaping FuturaThread.Task) {
            self.task = task
        }
    }
}

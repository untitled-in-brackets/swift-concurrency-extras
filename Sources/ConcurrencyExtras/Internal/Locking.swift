#if canImport(Android)
  import Android
  final class RecursiveLock: @unchecked Sendable {
    private var mutex = pthread_mutex_t()

    init() {
      var attributes = pthread_mutexattr_t()
      pthread_mutexattr_init(&attributes)
      pthread_mutexattr_settype(&attributes, Int32(PTHREAD_MUTEX_RECURSIVE))
      pthread_mutex_init(&mutex, &attributes)
      pthread_mutexattr_destroy(&attributes)
    }

    deinit {
      pthread_mutex_destroy(&mutex)
    }

    func sync<Result>(_ operation: () throws -> Result) rethrows -> Result {
      pthread_mutex_lock(&mutex)
      defer { pthread_mutex_unlock(&mutex) }
      return try operation()
    }
  }
#elseif Foundation && canImport(Foundation)
  public import Foundation

  final class RecursiveLock: @unchecked Sendable {
    private let mutex = NSRecursiveLock()

    func sync<Result>(_ operation: () throws -> Result) rethrows -> Result {
      mutex.lock()
      defer { mutex.unlock() }
      return try operation()
    }
  }

  extension NSRecursiveLock {
    @inlinable @discardableResult
    @_spi(Internals) public func sync<R>(work: () throws -> R) rethrows -> R {
      self.lock()
      defer { self.unlock() }
      return try work()
    }
  }
#else
  import Synchronization

  final class RecursiveLock: @unchecked Sendable {
    private let mutex = Mutex(())

    func sync<Result>(_ operation: () throws -> Result) rethrows -> Result {
      try mutex.withLock { _ in try operation() }
    }
  }
#endif

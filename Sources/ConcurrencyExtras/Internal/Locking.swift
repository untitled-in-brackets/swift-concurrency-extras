#if canImport(Darwin)
  import Darwin
#elseif canImport(Glibc)
  import Glibc
#elseif canImport(Musl)
  import Musl
#elseif canImport(Android)
  import Android
#elseif canImport(wasi_pthread)
  import wasi_pthread
#endif

#if canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android) || canImport(wasi_pthread)
  final class RecursiveLock: @unchecked Sendable {
    private let mutex: UnsafeMutablePointer<pthread_mutex_t>

    init() {
      let mutex = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
      self.mutex = mutex
      var attributes = pthread_mutexattr_t()
      pthread_mutexattr_init(&attributes)
      pthread_mutexattr_settype(&attributes, Int32(PTHREAD_MUTEX_RECURSIVE))
      pthread_mutex_init(mutex, &attributes)
      pthread_mutexattr_destroy(&attributes)
    }

    deinit {
      pthread_mutex_destroy(mutex)
      mutex.deallocate()
    }

    func sync<Result>(_ operation: () throws -> Result) rethrows -> Result {
      pthread_mutex_lock(mutex)
      defer { pthread_mutex_unlock(mutex) }
      return try operation()
    }
  }
#elseif os(WASI)
  final class RecursiveLock: @unchecked Sendable {
    func sync<Result>(_ operation: () throws -> Result) rethrows -> Result {
      try operation()
    }
  }
#elseif Foundation && canImport(Foundation)
  import Foundation

  final class RecursiveLock: @unchecked Sendable {
    private let mutex = NSRecursiveLock()

    func sync<Result>(_ operation: () throws -> Result) rethrows -> Result {
      mutex.lock()
      defer { mutex.unlock() }
      return try operation()
    }
  }
#elseif canImport(WinSDK)
  import WinSDK

  final class RecursiveLock: @unchecked Sendable {
    private let criticalSection: UnsafeMutablePointer<CRITICAL_SECTION>

    init() {
      let criticalSection = UnsafeMutablePointer<CRITICAL_SECTION>.allocate(capacity: 1)
      self.criticalSection = criticalSection
      InitializeCriticalSection(criticalSection)
    }

    deinit {
      DeleteCriticalSection(criticalSection)
      criticalSection.deallocate()
    }

    func sync<Result>(_ operation: () throws -> Result) rethrows -> Result {
      EnterCriticalSection(criticalSection)
      defer { LeaveCriticalSection(criticalSection) }
      return try operation()
    }
  }
#else
  #error("RecursiveLock is unsupported on this platform")
#endif

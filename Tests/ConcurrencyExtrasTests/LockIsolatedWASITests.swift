#if os(WASI)
  import ConcurrencyExtras
  import XCTest

  final class LockIsolatedWASITests: XCTestCase {
    func testWithValueSupportsReentrantReads() {
      let value = LockIsolated(0)
      value.withValue { _ in
        XCTAssertEqual(value.value, 0)
      }
    }
  }
#endif

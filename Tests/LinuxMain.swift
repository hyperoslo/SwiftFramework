#if os(Linux)

import XCTest
@testable import FlamingoTestSuite

XCTMain([
  testCase(ApplicationControllerTests.allTests),
])

#endif

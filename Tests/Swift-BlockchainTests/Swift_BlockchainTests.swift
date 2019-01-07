import XCTest
@testable import Swift_Blockchain

final class Swift_BlockchainTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Swift_Blockchain().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}

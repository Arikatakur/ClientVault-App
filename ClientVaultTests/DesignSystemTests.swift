import XCTest
@testable import ClientVault

final class DesignSystemTests: XCTestCase {
    func testSpacingScaleIsStrictlyIncreasing() {
        let scale: [CGFloat] = [
            Spacing.xxs, Spacing.xs, Spacing.sm, Spacing.md,
            Spacing.lg, Spacing.xl, Spacing.xxl, Spacing.xxxl
        ]
        XCTAssertEqual(scale, scale.sorted(), "spacing tokens must be ordered")
        XCTAssertEqual(Set(scale).count, scale.count, "spacing tokens must be distinct")
    }

    func testDefaultKDFParametersMeetMinimums() {
        let params = KDFParameters.default
        XCTAssertEqual(params.algorithm, .argon2id)
        // OWASP Argon2id guidance: >= ~19 MiB memory, multiple iterations, 16-byte salt.
        XCTAssertGreaterThanOrEqual(params.memoryKiB, 19 * 1024)
        XCTAssertGreaterThanOrEqual(params.iterations, 2)
        XCTAssertGreaterThanOrEqual(params.saltLength, 16)
    }
}

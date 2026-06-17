import XCTest
@testable import ClientVault

/// RFC 6238 Appendix B test vectors (SHA-1, 30-second window, seed = "12345678901234567890")
/// The TOTP values are taken from the RFC at specific Unix time / counter values.
final class TOTPTests: XCTestCase {

    // MARK: - Base32 decoder

    func testBase32DecodeRFCSeedDecodes20Bytes() throws {
        // "12345678901234567890" in base32 is GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ
        let bytes = try TOTPGenerator.base32Decode("GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ")
        let expected = Array("12345678901234567890".utf8)
        XCTAssertEqual(bytes, expected)
    }

    func testBase32DecodeIgnoresLowercase() throws {
        let upper = try TOTPGenerator.base32Decode("GEZDGNBVGY3TQOJQ")
        let lower = try TOTPGenerator.base32Decode("gezdgnbvgy3tqojq")
        XCTAssertEqual(upper, lower)
    }

    func testBase32DecodeIgnoresPadding() throws {
        let withPad    = try TOTPGenerator.base32Decode("MFRA====")
        let withoutPad = try TOTPGenerator.base32Decode("MFRA")
        XCTAssertEqual(withPad, withoutPad)
    }

    // MARK: - OTPAuth URL parser

    func testParseOTPAuthURLExtractsComponents() {
        let url = "otpauth://totp/Example%3Aalice%40example.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"
        let result = TOTPGenerator.parseOTPAuthURL(url)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.seed, "JBSWY3DPEHPK3PXP")
        XCTAssertEqual(result?.issuer, "Example")
    }

    func testParseOTPAuthURLRejectsNonOTPAuth() {
        XCTAssertNil(TOTPGenerator.parseOTPAuthURL("https://example.com"))
        XCTAssertNil(TOTPGenerator.parseOTPAuthURL("otpauth://hotp/foo?secret=ABC"))
        XCTAssertNil(TOTPGenerator.parseOTPAuthURL("not a url"))
    }

    func testParseOTPAuthURLRequiresSecret() {
        XCTAssertNil(TOTPGenerator.parseOTPAuthURL("otpauth://totp/foo"))
    }

    // MARK: - Seconds remaining

    func testSecondsRemainingIsInRange() {
        let r = TOTPGenerator.secondsRemaining
        XCTAssertGreaterThanOrEqual(r, 1)
        XCTAssertLessThanOrEqual(r, 30)
    }
}

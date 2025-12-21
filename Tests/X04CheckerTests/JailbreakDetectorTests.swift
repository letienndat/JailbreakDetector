import XCTest
@testable import X04Checker

final class JailbreakDetectorTests: XCTestCase {
    func testJailbreakURLSchemeFallsBackToDefaultWhenEmpty() {
        let detector = JailbreakDetector(
            writeTestPath: "/private/monkey_write_test",
            dependencies: makeDependencies(schemeProvider: { "  " })
        )

        XCTAssertEqual(detector.jailbreakURLScheme, "cydia")
    }

    func testJailbreakURLSchemeFallsBackToDefaultWhenNil() {
        let detector = JailbreakDetector(
            writeTestPath: "/private/monkey_write_test",
            dependencies: makeDependencies(schemeProvider: { nil })
        )

        XCTAssertEqual(detector.jailbreakURLScheme, "cydia")
    }

    func testJailbreakURLSchemeUsesProviderValue() {
        let detector = JailbreakDetector(
            writeTestPath: "/private/monkey_write_test",
            dependencies: makeDependencies(schemeProvider: { "sileo" })
        )

        XCTAssertEqual(detector.jailbreakURLScheme, "sileo")
    }

    func testJailbreakURLSchemeTrimsWhitespace() {
        let detector = JailbreakDetector(
            writeTestPath: "/private/monkey_write_test",
            dependencies: makeDependencies(schemeProvider: { "  sileo\n" })
        )

        XCTAssertEqual(detector.jailbreakURLScheme, "sileo")
    }

    func testHasJailbreakURLSchemeUsesSchemeURL() {
        var capturedURL: URL?
        let detector = JailbreakDetector(
            writeTestPath: "/private/monkey_write_test",
            dependencies: makeDependencies(
                schemeProvider: { "sileo" },
                canOpenURLHandler: { url in
                    capturedURL = url
                    return true
                }
            )
        )

        XCTAssertTrue(detector.hasJailbreakURLScheme())
        XCTAssertEqual(capturedURL?.absoluteString, "sileo://")
    }

    func testHasSuspiciousFilesReturnsTrueWhenAnyExists() {
        let match = String(JailbreakDetector.suspiciousPaths[0].reversed())
        let detector = JailbreakDetector(
            writeTestPath: "/private/monkey_write_test",
            dependencies: makeDependencies(fileExistsHandler: { $0 == match })
        )

        XCTAssertTrue(detector.hasSuspiciousFiles())
    }

    func testHasSuspiciousFilesReturnsFalseWhenNoneExist() {
        var checkedPaths: [String] = []
        let expectedPaths = JailbreakDetector.suspiciousPaths.map { String($0.reversed()) }
        let detector = JailbreakDetector(
            writeTestPath: "/private/monkey_write_test",
            dependencies: makeDependencies(fileExistsHandler: { path in
                checkedPaths.append(path)
                return false
            })
        )

        XCTAssertFalse(detector.hasSuspiciousFiles())
        XCTAssertEqual(checkedPaths, expectedPaths)
    }

    func testCanWriteOutsideSandboxUsesProvidedPath() {
        var capturedPath: String?
        let detector = JailbreakDetector(
            writeTestPath: "/private/test_path",
            dependencies: makeDependencies(writeTestHandler: { path in
                capturedPath = path
                return true
            })
        )

        XCTAssertTrue(detector.canWriteOutsideSandbox())
        XCTAssertEqual(capturedPath, "/private/test_path")
    }

    func testCanWriteOutsideSandboxUsesDefaultPath() {
        var capturedPath: String?
        let detector = JailbreakDetector(
            dependencies: makeDependencies(writeTestHandler: { path in
                capturedPath = path
                return false
            })
        )

        XCTAssertFalse(detector.canWriteOutsideSandbox())
        XCTAssertEqual(capturedPath, "/private/monkey_write_test")
    }

    func testIsJailbrokenRespectsSimulatorOverride() {
        let detector = JailbreakDetector(
            writeTestPath: "/private/monkey_write_test",
            dependencies: makeDependencies(
                canOpenURLHandler: { _ in true },
                fileExistsHandler: { _ in true },
                writeTestHandler: { _ in true }
            )
        )

        XCTAssertFalse(detector.isJailbroken(isSimulator: true))
        XCTAssertTrue(detector.isJailbroken(isSimulator: false))
    }

    func testIsJailbrokenReturnsTrueWhenURLSchemeCheckPasses() {
        let detector = JailbreakDetector(
            writeTestPath: "/private/monkey_write_test",
            dependencies: makeDependencies(canOpenURLHandler: { _ in true })
        )

        XCTAssertTrue(detector.isJailbroken(isSimulator: false))
    }

    func testIsJailbrokenReturnsTrueWhenFileCheckPasses() {
        let match = String(JailbreakDetector.suspiciousPaths[0].reversed())
        let detector = JailbreakDetector(
            writeTestPath: "/private/monkey_write_test",
            dependencies: makeDependencies(fileExistsHandler: { $0 == match })
        )

        XCTAssertTrue(detector.isJailbroken(isSimulator: false))
    }

    func testIsJailbrokenReturnsTrueWhenWriteCheckPasses() {
        let detector = JailbreakDetector(
            writeTestPath: "/private/monkey_write_test",
            dependencies: makeDependencies(writeTestHandler: { _ in true })
        )

        XCTAssertTrue(detector.isJailbroken(isSimulator: false))
    }

    func testIsJailbrokenReturnsFalseWhenChecksFail() {
        let detector = JailbreakDetector(
            writeTestPath: "/private/monkey_write_test",
            dependencies: makeDependencies()
        )

        XCTAssertFalse(detector.isJailbroken(isSimulator: false))
    }
}

private func makeDependencies(
    schemeProvider: @escaping () -> String? = { nil },
    canOpenURLHandler: @escaping (URL) -> Bool = { _ in false },
    fileExistsHandler: @escaping (String) -> Bool = { _ in false },
    writeTestHandler: @escaping (String) -> Bool = { _ in false }
) -> JailbreakDetector.Dependencies {
    JailbreakDetector.Dependencies(
        schemeProvider: schemeProvider,
        canOpenURLHandler: canOpenURLHandler,
        fileExistsHandler: fileExistsHandler,
        writeTestHandler: writeTestHandler
    )
}

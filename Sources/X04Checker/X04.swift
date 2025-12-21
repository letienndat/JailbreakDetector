import UIKit

public extension UIDevice {
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    public var x102: Bool {
        Self.isSimulator
    }

    public var x04: Bool {
        JailbreakDetector().isJailbroken(isSimulator: Self.isSimulator)
    }
}

struct JailbreakDetector {
    struct Dependencies {
        var schemeProvider: () -> String?
        var canOpenURLHandler: (URL) -> Bool
        var fileExistsHandler: (String) -> Bool
        var writeTestHandler: (String) -> Bool

        static func live(bundle: Bundle = .main) -> Dependencies {
            Dependencies(
                schemeProvider: { bundle.object(forInfoDictionaryKey: "X0R_KEY") as? String },
                canOpenURLHandler: { UIApplication.shared.canOpenURL($0) },
                fileExistsHandler: { FileManager.default.fileExists(atPath: $0) },
                writeTestHandler: { path in
                    do {
                        try "x".write(toFile: path, atomically: true, encoding: .utf8)
                        try? FileManager.default.removeItem(atPath: path)
                        return true
                    } catch {
                        return false
                    }
                }
            )
        }
    }

    private let dependencies: Dependencies
    private let writeTestPath: String

    init(
        bundle: Bundle = .main,
        writeTestPath: String = "/private/monkey_write_test",
        dependencies: Dependencies? = nil
    ) {
        self.writeTestPath = writeTestPath
        self.dependencies = dependencies ?? Dependencies.live(bundle: bundle)
    }

    var jailbreakURLScheme: String {
        if let scheme = dependencies.schemeProvider()?.trimmingCharacters(in: .whitespacesAndNewlines),
           !scheme.isEmpty {
            return scheme
        }
        return "cydia"
    }

    func isJailbroken(isSimulator: Bool) -> Bool {
        guard !isSimulator else { return false }
        return hasJailbreakURLScheme() || hasSuspiciousFiles() || canWriteOutsideSandbox()
    }

    func hasJailbreakURLScheme() -> Bool {
        guard let url = URL(string: "\(jailbreakURLScheme)://") else { return false }
        return dependencies.canOpenURLHandler(url)
    }

    func hasSuspiciousFiles() -> Bool {
        for path in Self.suspiciousPaths {
            let decoded = String(path.reversed())
            if dependencies.fileExistsHandler(decoded) {
                return true
            }
        }
        return false
    }

    func canWriteOutsideSandbox() -> Bool {
        dependencies.writeTestHandler(writeTestPath)
    }

    static let suspiciousPaths: [String] = [
        "ppa.aidyC/snoitacilppA/",
        "ppa.n1arkcalb/snoitacilppA/",
        "ppa.reirraCekaF/snoitacilppA/",
        "ppa.rev0cnu/snoitacilppA/",
        "bilyd.etartsbuSeliboM/etartsbuSeliboM/yrarbiL/",
        "tsilp.putratS.aidyC.kiruas.moc/snomeaDhcnuaL/yrarbiL/",
        "tpa/bil/rav/etavirp/",
        "hsats/rav/etavirp/",
        "gol.aidyc/pmt/rav/etavirp/",
        "ofni/aidyc/bil/rav/etavirp/",
        "semehT/sgnitteSBS/yrarbiL/elibom/rav/etavirp/",
        "dhss/nibs/rsu/",
        "ngisyek-hss/cexebil/rsu/",
        "hsab/nib/",
        "tpa/cte/",
        "hss/nib/rsu/"
    ]
}

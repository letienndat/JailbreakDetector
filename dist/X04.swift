import UIKit

public extension UIDevice {
    static var x010: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    public var x102: Bool {
        Self.x010
    }

    public var x04: Bool {
        x001().x009(x010: Self.x010)
    }
}

struct x001 {
    struct x000 {
        var x014: () -> String?
        var x002: (URL) -> Bool
        var x006: (String) -> Bool
        var x017: (String) -> Bool

        static func x012(bundle: Bundle = .main) -> x000 {
            x000(
                x014: { bundle.object(forInfoDictionaryKey: "X0R_KEY") as? String },
                x002: { UIApplication.shared.canOpenURL($0) },
                x006: { FileManager.default.fileExists(atPath: $0) },
                x017: { path in
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

    private let x005: x000
    private let x018: String

    init(
        bundle: Bundle = .main,
        x018: String = "/private/monkey_write_test",
        x005: x000? = nil
    ) {
        self.x018 = x018
        self.x005 = x005 ?? x000.x012(bundle: bundle)
    }

    var x011: String {
        if let x013 = x005.x014()?.trimmingCharacters(in: .whitespacesAndNewlines),
           !x013.isEmpty {
            return x013
        }
        return "cydia"
    }

    func x009(x010: Bool) -> Bool {
        guard !x010 else { return false }
        return x007() || x008() || x003()
    }

    func x007() -> Bool {
        guard let x016 = URL(string: "\(x011)://") else { return false }
        return x005.x002(x016)
    }

    func x008() -> Bool {
        for path in Self.x015 {
            let x004 = String(path.reversed())
            if x005.x006(x004) {
                return true
            }
        }
        return false
    }

    func x003() -> Bool {
        x005.x017(x018)
    }

    static let x015: [String] = [
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

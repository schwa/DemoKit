import Foundation

public struct DemoCrashDetector {
    public static func install() {

        if FileManager.default.fileExists(atPath: CrashFlag.flag.path) {
            UserDefaults.standard.removeObject(forKey: "demoview")
            try? FileManager.default.removeItem(at: CrashFlag.flag)
        }

        installCrashFlagSignalHandlers()
    }
}

final class CrashFlag {
    static let dir: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let d = base.appendingPathComponent(Bundle.main.bundleIdentifier ?? "App", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }()
    static let flag = dir.appendingPathComponent("crash.flag")
}

@_cdecl("cr_signal_handler")
private func cr_signal_handler(_ sig: Int32) {
    // async-signal-safe only
    let path = (CrashFlag.flag.path as NSString).fileSystemRepresentation
    let fd = open(path, O_WRONLY|O_CREAT|O_APPEND, 0o644)
    if fd >= 0 {
        var b = UInt8(truncatingIfNeeded: sig)
        _ = withUnsafePointer(to: &b) { ptr in
            write(fd, ptr, 1)
        }
        close(fd)
    }
    _exit(sig)
}

func installCrashFlagSignalHandlers() {
    var sa = sigaction()
    sa.__sigaction_u = unsafeBitCast(cr_signal_handler as @convention(c) (Int32)->Void,
                                     to: __sigaction_u.self)
    sigemptyset(&sa.sa_mask)
    sa.sa_flags = 0
    for s in [SIGABRT, SIGILL, SIGSEGV, SIGFPE, SIGBUS, SIGPIPE] { sigaction(s, &sa, nil) }
}

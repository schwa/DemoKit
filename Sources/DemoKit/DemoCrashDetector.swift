import Foundation

public enum DemoCrashDetector {
    public static func install() {
        if FileManager.default.fileExists(atPath: CrashFlag.flag.path) {
            UserDefaults.standard.removeObject(forKey: "demoview")
            try? FileManager.default.removeItem(at: CrashFlag.flag)
        }

        installCrashFlagSignalHandlers()
    }
}

enum CrashFlag {
    static let dir: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = base.appendingPathComponent(Bundle.main.bundleIdentifier ?? "App", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }()
    static let flag = dir.appendingPathComponent("crash.flag")
}

@_cdecl("cr_signal_handler")
private func cr_signal_handler(_ sig: Int32) {
    // async-signal-safe only
    let path = (CrashFlag.flag.path as String).withCString { $0 }
    let fileDescriptor = open(path, O_WRONLY | O_CREAT | O_APPEND, 0o644)
    if fileDescriptor >= 0 {
        var byte = UInt8(truncatingIfNeeded: sig)
        _ = withUnsafePointer(to: &byte) { ptr in
            write(fileDescriptor, ptr, 1)
        }
        close(fileDescriptor)
    }
    _exit(sig)
}

func installCrashFlagSignalHandlers() {
    var action = sigaction()
    action.__sigaction_u = unsafeBitCast(
        cr_signal_handler as @convention(c) (Int32) -> Void,
        to: __sigaction_u.self
    )
    sigemptyset(&action.sa_mask)
    action.sa_flags = 0
    for sig in [SIGABRT, SIGILL, SIGSEGV, SIGFPE, SIGBUS, SIGPIPE] { sigaction(sig, &action, nil) }
}

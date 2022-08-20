import Foundation
@_implementationOnly import os
@_implementationOnly import RegexBuilder
import SwiftUI
#if os(macOS)
@_implementationOnly import AppKit
#endif
@_implementationOnly import AsyncAlgorithms

private let logger = Logger(subsystem: "TODO", category: "TODO")

extension View {
    /// UNTESTED DO NOT USE
    func throwingTask(priority: TaskPriority = .userInitiated, _ action: @escaping @Sendable () async throws -> Void) -> some View {
        return task(priority: priority) {
            do {
                try await action()
            } catch {
                fatalError("\(error)")
            }
        }
    }
}

extension Duration: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = Duration(value)
    }
}

extension Duration: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int64) {
        self = Duration(secondsComponent: value, attosecondsComponent: 0)
    }
}

extension Duration {
    init(_ timeInterval: TimeInterval) {
        // 1×10−18

        let fraction = timeInterval - floor(timeInterval)
        self = .init(secondsComponent: Int64(timeInterval), attosecondsComponent: Int64(fraction * 1e18))
    }
}

extension FormatStyle where Self == Duration.TimeFormatStyle {
    static var duration: Duration.TimeFormatStyle {
        return Duration.TimeFormatStyle(pattern: .minuteSecond(padMinuteToLength: 2, fractionalSecondsLength: 3))
    }
}

// extension Text {
//    init<F>(_ input: F.FormatInput, format: F) where F : FormatStyle, F.FormatInput : Equatable, F.FormatOutput == Duration {
//        fatalError()
//    }
// }

@_spi(DemoKit)
public struct MySortComparator<Compared, Key>: SortComparator, Hashable where Key: Comparable {
    let keyPath: KeyPath<Compared, Key>
    public var order: SortOrder

    public init(_ keyPath: KeyPath<Compared, Key>, order: SortOrder = .forward) {
        self.keyPath = keyPath
        self.order = order
    }

    public func compare(_ lhs: Compared, _ rhs: Compared) -> ComparisonResult {
        return ComparisonResult(lhs: lhs[keyPath: keyPath], rhs: rhs[keyPath: keyPath])
    }
}

extension ComparisonResult {
    init<C>(lhs: C, rhs: C, sortOrder: SortOrder = .forward) where C: Comparable {
        if lhs < rhs {
            self = sortOrder == .forward ? .orderedAscending : .orderedDescending
        } else if lhs == rhs {
            self = .orderedSame
        } else {
            self = sortOrder == .forward ? .orderedDescending : .orderedAscending
        }
    }
}

struct MyToggleStyle: ToggleStyle {
    let on: String
    let off: String

    func makeBody(configuration: Configuration) -> some View {
        Group {
            switch configuration.isOn {
            case true:
                Image(systemName: on).contentShape(Rectangle())
            case false:
                Image(systemName: off).contentShape(Rectangle())
            }
        }
        .onTapGesture {
            configuration.isOn.toggle()
        }
    }
}

protocol EncoderProtocol {
    func encode<T>(_ value: T) throws -> Data where T: Encodable
}

extension JSONEncoder: EncoderProtocol {}

extension Encodable {
    func write<T>(to url: URL, encoder _: T) throws where T: EncoderProtocol {
        let data = try JSONEncoder().encode(self)
        try data.write(to: url)
    }
}

extension FileManager {
    var applicationSupportDirectory: URL {
        guard let url = urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError()
        }
        return url
    }

    func fileExists(at url: URL, isDirectory: inout Bool) -> Bool {
        var isDirectoryObjc = ObjCBool(false)
        let result = fileExists(atPath: url.path, isDirectory: &isDirectoryObjc)
        isDirectory = isDirectoryObjc.boolValue
        return result
    }

    func directoryExists(at url: URL) -> Bool {
        var isDirectory = false
        if fileExists(at: url, isDirectory: &isDirectory) {
            return isDirectory
        } else {
            return false
        }
    }

    func createFile(at url: URL, contents: Data? = nil, attributes: [FileAttributeKey: Any]? = nil, createIntermediates: Bool = false) throws {
        logger.log("\(FileManager().currentDirectoryPath)")

        if createIntermediates {
            let parent = url.deletingLastPathComponent()
            if directoryExists(at: parent) == false {
                try createDirectory(at: parent, withIntermediateDirectories: true)
            }
        }

        if createFile(atPath: url.path, contents: contents, attributes: attributes) == false {
            guard let error = POSIXErrorCode(rawValue: errno).map({ POSIXError($0) }) else {
                fatalError("Unknown errno: \(errno)")
            }
            throw error
        }
    }

    @discardableResult
    func removeItemIfExists(at: URL) throws -> Bool {
        if fileExists(at: at) {
            try removeItem(at: at)
            return true
        } else {
            return false
        }
    }

    func fileExists(at: URL) -> Bool {
        return fileExists(atPath: at.path)
    }

    func copyItem(at: URL, to: URL, replacingIfExists _: Bool = false) throws {
        if fileExists(at: to) {
            try removeItem(at: to)
        }
        try copyItem(at: at, to: to)
    }

    func moveItem(at: URL, to: URL, replacingIfExists _: Bool = false) throws {
        if fileExists(at: to) {
            try removeItem(at: to)
        }
        try moveItem(at: at, to: to)
    }
}

extension FileHandle {
    func readPrefixedRecord() throws -> Data? {
        guard let count = try read(type: Int.self) else {
            return nil
        }
        guard let data = try read(upToCount: count), data.count == count else {
            return nil
        }
        return data
    }

    func writePrefixedRecord<D>(_ data: D) throws where D: DataProtocol {
        try withUnsafeBytes(of: data.count) { count in
            let buffer = Data(count) + Data(data)
            try write(contentsOf: buffer)
        }
    }

    func read<T>(type _: T.Type) throws -> T? {
        let saved = try offset()
        guard let data = try read(upToCount: MemoryLayout<T>.size), data.count == MemoryLayout<T>.size else {
            try seek(toOffset: saved)
            return nil
        }
        return data.withUnsafeBytes { buffer in
            buffer.load(as: T.self)
        }
    }
}

struct LazyView<Content>: View where Content: View {
    let content: () -> Content
    init(@ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
    }

    var body: Content {
        content()
    }
}

// MARK: -

@_spi(DemoKit)
public struct CrashDetectionView<Content>: View where Content: View {
    enum Crash: String {
        case unknown
        case potential
    }

    enum LifeCycle {
        case unknown
        case unstable
        case stable
    }

    let id: String
    let unstableTime: TimeInterval
    let showLifeCycle: Bool

    let lastCrash: Crash

    @State
    var lifeCycle = LifeCycle.unknown

    @State
    var override = false

    let content: () -> Content

    let key: String

    public init(id: String, unstableTime: TimeInterval = 2, showLifeCycle: Bool = false, content: @escaping () -> Content) {
        self.id = id
        self.unstableTime = unstableTime
        self.showLifeCycle = showLifeCycle
        self.content = content
        self.key = "io.schwa.crash-detection-view-\(id)-lastcrash"
        let lastCrash = UserDefaults.standard.string(forKey: key).map { Crash(rawValue: $0)! } ?? .unknown
        logger.log("\(String(describing: lastCrash))")
        self.lastCrash = lastCrash
    }

    public var body: some View {
        Group {
            switch (lastCrash, override) {
            case (.unknown, _), (_, true):
                content()
                    .onAppear {
                        logger.log("onAppear: \(id)")
                        markUnstable()
                    }
                    .onDisappear {
                        logger.log("onDisappear: \(id)")
                        markStable()
                    }
                    .task {
                        do {
                            try await Task.sleep(until: .now + .seconds(unstableTime), clock: .continuous)
                            logger.log("slept: \(id)")
                            markStable()
                        } catch {
                            logger.log("Error: \(error)")
                        }
                    }
            case (.potential, false):
                VStack {
                    Text("Potential crash")
                    Button("Launch anyway?") {
                        override = true
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .overlay(alignment: .bottom) {
            if showLifeCycle {
                HUDView {
                    VStack {
                        Text("Life cycle: \(String(describing: lifeCycle))")
                        Text("Last Crash: \(String(describing: lastCrash))")
                    }
                }
                .padding()
            }
        }
    }

    func markUnstable() {
        logger.log("markUnstable: \(String(describing: lifeCycle)), \(String(describing: lastCrash))")
        if lifeCycle != .unstable {
            lifeCycle = .unstable
            UserDefaults.standard.set(Crash.potential.rawValue, forKey: key)
        }
    }

    func markStable() {
        logger.log("stabilize: \(String(describing: lifeCycle)), \(String(describing: lastCrash))")
        if lifeCycle != .stable {
            lifeCycle = .stable
            UserDefaults.standard.set(Crash.unknown.rawValue, forKey: key)
        }
    }
}

struct HUDView<Content>: View where Content: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding()
            .background(.thickMaterial)
            .overlay(ContainerRelativeShape().strokeBorder(Color.white, lineWidth: 4))
            .containerShape(RoundedRectangle(cornerSize: .init(width: 8, height: 8)))
    }
}

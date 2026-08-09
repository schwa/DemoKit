import SwiftUI

/// Options for the `screenshot` URL action, parsed from the URL's query items.
public struct ScreenshotOptions: Sendable, Equatable {
    public enum Format: String, Sendable, CaseIterable {
        // swiftlint:disable explicit_enum_raw_value
        case png
        case jpg
        // swiftlint:enable explicit_enum_raw_value

        var fileExtension: String { rawValue }
    }

    public var width: Double = 800
    public var height: Double = 600
    public var scale: Double = 2
    public var format: Format = .png
    /// A file path or a directory. When `nil` the screenshot is written to the temporary directory.
    public var destination: URL?
    public var reveal = true
    public var background: Color = .white

    public init() {}

    /// Parses options from a URL such as `x-demo://screenshot?width=1200&format=jpg`.
    /// Unparseable values are ignored and the default is kept.
    public static func parse(from url: URL) -> Self {
        var options = Self()
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return options
        }

        for item in queryItems {
            guard let value = item.value, !value.isEmpty else { continue }
            options.apply(name: item.name.lowercased(), value: value)
        }
        return options
    }

    // swiftlint:disable:next cyclomatic_complexity
    private mutating func apply(name: String, value: String) {
        switch name {
        case "width":
            if let number = Double(value), number > 0 { width = number }

        case "height":
            if let number = Double(value), number > 0 { height = number }

        case "scale":
            if let number = Double(value), number > 0 { scale = number }

        case "format":
            if let format = Format(rawValue: Self.normalizedFormat(value)) { self.format = format }

        case "destination", "path":
            destination = URL(filePath: Self.expandingTilde(value))

        case "reveal":
            if let reveal = Self.parseBool(value) { self.reveal = reveal }

        case "background":
            if let color = Self.parseColor(value) { background = color }

        default:
            logger?.warning("Unknown screenshot parameter: \(name)")
        }
    }

    /// The URL to write to, given the demo being captured.
    func fileURL(demoID: String) -> URL {
        let filename = "DemoKit-\(demoID).\(format.fileExtension)"
        guard let destination else {
            return FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        }
        if destination.pathExtension.isEmpty {
            return destination.appendingPathComponent(filename)
        }
        return destination
    }

    private static func normalizedFormat(_ value: String) -> String {
        let lowered = value.lowercased()
        return lowered == "jpeg" ? "jpg" : lowered
    }

    // swiftlint:disable:next discouraged_optional_boolean
    private static func parseBool(_ value: String) -> Bool? {
        switch value.lowercased() {
        case "true", "yes", "1":
            true

        case "false", "no", "0":
            false

        default:
            nil
        }
    }

    private static let namedColors: [String: Color] = [
        "white": .white,
        "black": .black,
        "clear": .clear,
        "transparent": .clear,
        "none": .clear,
        "gray": .gray,
        "grey": .gray,
        "red": .red,
        "green": .green,
        "blue": .blue,
        "yellow": .yellow,
        "orange": .orange,
        "purple": .purple
    ]

    private static func expandingTilde(_ path: String) -> String {
        guard path == "~" || path.hasPrefix("~/") else { return path }
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return home + path.dropFirst(1)
    }

    private static func parseColor(_ value: String) -> Color? {
        namedColors[value.lowercased()] ?? hexColor(value)
    }

    private static func hexColor(_ value: String) -> Color? {
        var hex = value.hasPrefix("#") ? String(value.dropFirst()) : value
        if hex.count == 3 {
            hex = hex.map { "\($0)\($0)" }.joined()
        }
        guard hex.count == 6, let packed = UInt32(hex, radix: 16) else { return nil }
        return Color(
            red: Double((packed >> 16) & 0xFF) / 255,
            green: Double((packed >> 8) & 0xFF) / 255,
            blue: Double(packed & 0xFF) / 255
        )
    }
}

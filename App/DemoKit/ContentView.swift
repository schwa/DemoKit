import SwiftUI
import Foundation
import RegexBuilder
import os
#if os(macOS)
import AppKit
#endif
import AsyncAlgorithms

let logger = Logger(subsystem: "TODO", category: "TODO")

struct ContentView: View {
    var body: some View {
        UserDefaultsView()
    }
}


struct DemosView: View {

    @Environment(\.scenePhase)
    var scenePhase

    @StateObject
    var model = DemoModel {
        AnyDemo("Red Demo") {
            Color.red
        }
        AnyDemo("Green Demo") {
            Color.green
        }
        AnyDemo("Blue Demo") {
            Color.blue
        }
    }

    @AppStorage("selectedDemo") // TODO: Should be SceneStorage
    var sidebarSelection: String = ""

    @State
    var searchText: String = ""

    var filteredDemos: [AnyDemo] {
        let pattern = Regex { searchText }.ignoresCase()
        return Array(model.allDemos.values
            .filter { searchText.isEmpty || $0.title.contains(pattern) }
            .sorted(using: MySortComparator(\.title)))
    }

    init() {
        logger.log("INIT")
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $sidebarSelection) {
                ForEach(filteredDemos) { demo in
                    DemoRow(demo: demo, metadata: model.demoMetadata[demo.id]!)
                }
            }
            .searchable(text: $searchText, placement: .sidebar, prompt: "search…")
        } detail: {
            if let demo = model.allDemos[sidebarSelection] {
                CrashDetectionView(id: demo.id, showLifeCycle: true) {
                    DemoView(demo: demo)
                }
                .id(demo.id)
            }
        }
        .environmentObject(model)
        .onChange(of: scenePhase) { scenePhase in
            logger.log("\(String(describing: scenePhase))")
        }
#if os(macOS)
        //        .task {
        //            do {
        //                let n = NotificationCenter.default.notifications(named: NSApplication.willTerminateNotification)
        //                for try await x in n {
        //                    logger.log("\(x)")
        //                }
        //            }
        //            catch {
        //            }
        //        }
#endif
    }
}

struct DemoView: View {
    @EnvironmentObject
    var model: DemoModel

    let demo: AnyDemo

    var body: some View {
        demo.body
    }
}

// TODO: Doesn't work!?
extension View {
    func throwingTask(priority: TaskPriority = .userInitiated, _ action: @escaping @Sendable () async throws -> Void) -> some View {
        return task(priority: priority) {
            do {
                try await action()
            }
            catch {
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

struct DemoRow: View {

    @EnvironmentObject
    var model: DemoModel

    let demo: AnyDemo

    @State
    var metadataDisplayed = false

    @State
    var metadata: DemoMetadata

    var body: some View {
        return HStack {
            Toggle("Star", isOn: $metadata.starred)
                .toggleStyle(MyToggleStyle(on: "star.fill", off: "star"))
            Text(demo.title)
            Spacer()
            Button {
                metadataDisplayed = true
            } label: {
                Image(systemName: "info.circle")
            }
            .buttonStyle(.borderless)
            .popover(isPresented: $metadataDisplayed) {
                let metadata = model.demoMetadata[demo.id]! // TODO: Bang
                Form {
                    LabeledContent("ID", value: demo.id)
                    LabeledContent("Title", value: demo.title)
                    LabeledContent("Tags", value: metadata.tags.joined(separator: ", ")) // TODO: list format
                    LabeledContent("Comments") {
                        TextField("comment", text: $metadata.comments)
                    }
                    TimelineView(.animation) { time in
                        LabeledContent("Last Launched") {
                            if let value = metadata.lastLaunched {
                                Text(value, format: .dateTime)
                            }
                        }
                        LabeledContent("Last Duration") {
                            if let value = metadata.lastDuration {
                                Text(Duration(value), format: .duration)
                                //                                Text(value, format: .number)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .onChange(of: metadata) { newValue in
            model.demoMetadata[demo.id] = metadata
        }
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


extension Text {
    init<F>(_ input: F.FormatInput, format: F) where F : FormatStyle, F.FormatInput : Equatable, F.FormatOutput == Duration {
        fatalError()

    }
}

// MARK: -

class DemoModel: ObservableObject {

    @Published
    var allDemos: [String: AnyDemo] = [:]

    @Published
    //    var demoMetadata: [String: DemoMetadata] = [:]
    var demoMetadata = try! MiniDatabase<DemoMetadata>(url: FileManager().applicationSupportDirectory.appending(path: "test.journal"))
}

@resultBuilder
struct DemosBuilder {
    static func buildBlock(_ components: any Demo...) -> [AnyDemo] {
        return components.map { AnyDemo($0) }
    }

}

extension DemoModel {
    convenience init(@DemosBuilder _ demos: () -> [AnyDemo]) {
        let demos = demos()
        self.init()
        for demo in demos {
            allDemos[demo.id] = demo
            demoMetadata[demo.id] = .init(demo: demo.id, tags: [], comments: "", lastLaunched: nil, lastDuration: nil)
        }
    }
}

protocol Demo: Identifiable {
    associatedtype Content where Content: View
    var id: String { get }
    var title: String { get }
    var body: Content { get }
}

struct AnyDemo: Demo {
    let id: String
    let title: String
    let view: () -> AnyView

    init <Base>(_ base: Base) where Base: Demo {
        self.id = base.id
        self.title = base.title
        self.view = {
            AnyView(base.body)
        }
    }

    var body: some View {
        return view()
    }
}

extension AnyDemo {
    init <Content>(_ title: String, @ViewBuilder body: @escaping () -> Content) where Content: View {
        self.id = title
        self.title = title
        self.view = {
            AnyView(body())
        }
    }
}

struct DemoMetadata: Equatable, Codable {
    let demo: String
    var tags: Set<String>
    var comments: String
    var lastLaunched: Date?
    var lastDuration: TimeInterval?
}

extension DemoMetadata {
    var starred: Bool {
        get {
            return tags.contains("starred")
        }
        set {
            if newValue {
                logger.log("INSERTING")
                tags.insert("starred")
            }
            else {
                logger.log("REMOVING")
                tags.remove("starred")
            }

        }
    }
}

struct MySortComparator <Compared, Key>: SortComparator, Hashable where Key: Comparable {
    let keyPath: KeyPath<Compared, Key>
    var order: SortOrder

    init(_ keyPath: KeyPath<Compared, Key>, order: SortOrder = .forward) {
        self.keyPath = keyPath
        self.order = order
    }

    func compare(_ lhs: Compared, _ rhs: Compared) -> ComparisonResult {
        return ComparisonResult(lhs: lhs[keyPath: keyPath], rhs: rhs[keyPath: keyPath])
    }

}

extension ComparisonResult {
    init <C>(lhs: C, rhs: C, sortOrder: SortOrder = .forward) where C: Comparable {
        if lhs < rhs {
            self = sortOrder == .forward ? .orderedAscending : .orderedDescending
        }
        else if lhs == rhs {
            self = .orderedSame
        }
        else {
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

class MiniDatabase <Value: Codable> {

    typealias Key = String

    @Published
    var values: [Key: Value] = [:]
    let url: URL
    var journal: FileHandle!

    var queue = DispatchQueue(label: "minidata-write")

    enum Record: Codable {
        case start
        case set(Key, Value)
        case delete(Key)
        case snapshot([Key: Value])
    }

    init(url: URL) throws {
        self.url = url
        try read()
    }

    subscript(key: Key) -> Value? {
        get {
            return values[key]
        }
        set {
            values[key] = newValue
            let record: Record
            if let newValue = newValue {
                record = .set(key, newValue)
            }
            else {
                record = .delete(key)
            }
            try! write(record: record, handle: journal)
        }
    }

    func read() throws {
        try journal?.close()

        // TODO: remove backup


        var snapshot: Record?
        if FileManager().fileExists(at: url) {

            let input = try FileHandle(forReadingFrom: url)
            var values: [Key: Value] = [:]
            while let data = try input.readPrefixedRecord() {
                let record = try JSONDecoder().decode(Record.self, from: data)
                switch record {
                case .set(let key, let value):
                    values[key] = value
                case .delete(let key):
                    values[key] = nil
                case .snapshot(let values):
                    self.values = values
                default:
                    fatalError()
                }
            }
            snapshot = Record.snapshot(values)
        }

        // TODO: Not atomic
        try FileManager().removeItemIfExists(at: url)
        try FileManager().createFile(at: url, createIntermediates: true)
        self.journal = try FileHandle(forWritingTo: url)
        if let snapshot {
            try write(record: snapshot, handle: journal)
        }
    }

    func write(record: Record, handle: FileHandle) throws {
        queue.async {
            do {
                logger.log("Writing: \(String(describing: record))")
                let data = try JSONEncoder().encode(record)
                try handle.writePrefixedRecord(data)
            }
            catch {
                logger.error("Failed to write: \(error)")
            }
        }
    }
}

protocol EncoderProtocol {
    func encode<T>(_ value: T) throws -> Data where T : Encodable
}

extension JSONEncoder: EncoderProtocol {

}

extension Encodable {
    func write <T>(to url: URL, encoder: T) throws where T: EncoderProtocol {
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
        var isDirectory: Bool = false
        if fileExists(at: url, isDirectory: &isDirectory) {
            return isDirectory
        }
        else {
            return false
        }
    }

    func createFile(at url: URL, contents: Data? = nil, attributes: [FileAttributeKey : Any]? = nil, createIntermediates: Bool = false) throws {
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
        }
        else {
            return false
        }
    }

    func fileExists(at: URL) -> Bool {
        return fileExists(atPath: at.path)
    }

    func copyItem(at: URL, to: URL, replacingIfExists: Bool = false) throws {
        if fileExists(at: to) {
            try removeItem(at: to)
        }
        try copyItem(at: at, to: to)
    }

    func moveItem(at: URL, to: URL, replacingIfExists: Bool = false) throws {
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

    func writePrefixedRecord <D>(_ data: D) throws where D: DataProtocol {
        try withUnsafeBytes(of: data.count) { count in
            let buffer = Data(count) + Data(data)
            try write(contentsOf: buffer)
        }
    }

    func read <T>(type: T.Type) throws -> T? {
        let saved = try offset()
        guard let data = try read(upToCount: MemoryLayout<T>.size), data.count == MemoryLayout<T>.size else {
            try self.seek(toOffset: saved)
            return nil
        }
        return data.withUnsafeBytes { buffer in
            buffer.load(as: T.self)
        }
    }
}

extension MiniDatabase: ObservableObject {
}

extension MiniDatabase: Sequence {

    struct Iterator: IteratorProtocol {

        func next() -> (Key, Value)? {
            fatalError()
        }

    }

    func makeIterator() -> Iterator {
        fatalError()
    }

}

extension MiniDatabase: Collection {
    func index(after i: Index) -> Index {
        fatalError()
    }

    subscript(position: Index) -> Element {
        _read {
            fatalError()
        }
    }

    typealias Element = (Key, Value)

    struct Index: Comparable {
        static func < (lhs: Self, rhs: Self) -> Bool {
            fatalError()
        }
    }

    var startIndex: Index {
        fatalError()
    }
    var endIndex: Index {
        fatalError()
    }

}

extension MiniDatabase: BidirectionalCollection {
    func index(before i: Index) -> Index {
        fatalError()
    }
}

extension MiniDatabase: RandomAccessCollection {
}

public struct LazyView <Content>: View where Content: View {
    private let content: () -> Content
    public init(@ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
    }
    public var body: Content {
        content()
    }
}


public struct CrashDetectionView <Content>: View where Content: View {

    public enum Crash: String {
        case unknown
        case potential
    }

    public enum LifeCycle {
        case unknown
        case unstable
        case stable
    }


    let id: String
    let showLifeCycle: Bool
    let unstableTime: TimeInterval = 2

    let lastCrash: Crash

    @State
    var lifeCycle = LifeCycle.unknown

    @State
    var override = false

    let content: () -> Content

    public init(id: String, showLifeCycle: Bool = false, content: @escaping () -> Content) {
        self.id = id
        self.showLifeCycle = showLifeCycle
        self.content = content

        let lastCrash = UserDefaults.standard.string(forKey: "\(id)_lastCrash").map { Crash(rawValue: $0)! } ?? .unknown
        logger.log("\(String(describing: lastCrash))")
        self.lastCrash = lastCrash
    }

    public var body: some View {
        Group {
            switch (lastCrash, override) {
            case (.unknown, _), (_, true):
                content()
                    .onAppear() {
                        logger.log("onAppear: \(id)")
                        markUnstable()
                    }
                    .onDisappear() {
                        logger.log("onDisappear: \(id)")
                        markStable()
                    }
                    .task {
                        do {
                            try await Task.sleep(until: .now + .seconds(unstableTime), clock: .continuous)
                            logger.log("slept: \(id)")
                            markStable()
                        }
                        catch {
                            logger.log("Error: \(error)")
                        }
                    }
                    .overlay {
                        if showLifeCycle {
                            HUDView {
                                VStack {
                                    Text("Life cycle: \(String(describing: lifeCycle))")
                                    Text("Last Crash: \(String(describing: lastCrash))")
                                }
                            }
                        }
                    }
            case (.potential, false):
                Text("Potential crash?")
                Button("Launch anyway") {
                    override = true
                }
            }
        }

    }

    func markUnstable() {
        logger.log("markUnstable: \(String(describing: lifeCycle)), \(String(describing: lastCrash))")
        if lifeCycle != .unstable {
            lifeCycle = .unstable
            UserDefaults.standard.set(Crash.potential.rawValue, forKey: "\(id)_lastCrash")
        }
    }

    func markStable() {
        logger.log("stabilize: \(String(describing: lifeCycle)), \(String(describing: lastCrash))")
        if lifeCycle != .stable {
            lifeCycle = .stable
            UserDefaults.standard.set(Crash.unknown.rawValue, forKey: "\(id)_lastCrash")
        }
    }
}

struct HUDView <Content>: View where Content: View {

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

struct UserDefaultsView: View {

    struct Record: Identifiable {
        let id: [AnyHashable]
        let key: String

        enum Value {
            case boolean(Bool)
            case integer(Int)
            case float(Double)
            case string(String)
            case array([Any])
            case dictionary([String: Any])
            case data(Data)
            case date(Date)
            case unknown(Any)

            var typeName: String {
                let type: String
                switch self {
                case .boolean:
                    type = "boolean"
                case .integer:
                    type = "integer"
                case .float:
                    type = "float"
                case .string:
                    type = "string"
                case .array:
                    type = "array"
                case .dictionary:
                    type = "dictionary"
                case .data:
                    type = "data"
                case .date:
                    type = "date"
                case .unknown:
                    type = "unknown"
                }
                return type
            }
        }
        let value: Value
    }

    @State
    var records: [Record]

    @State
    var filteredRecords: [Record]

    @State
    var searchText: String = ""

    init() {
        let items: [(key: String, value: Any)] = Array(UserDefaults.standard.dictionaryRepresentation())
        let records = items.enumerated().map { (index, item) in
            let value: Record.Value
            switch item.value {
            case let o as Bool:
                value = .boolean(o)
            case let o as Int:
                value = .integer(o)
            case let o as Double:
                value = .float(o)
            case let o as String:
                value = .string(o)
            case let o as Data:
                value = .data(o)
            case let o as Date:
                value = .date(o)
            case let o as Array<Any>:
                value = .array(o)
            case let o as Dictionary<String, Any>:
                value = .dictionary(o)
            default:
                value = .unknown(item.value)
            }
            return Record(id: [index], key: item.key, value: value)
        }
        let filteredRecords = records.sorted(using: MySortComparator(\.key))

        self.records = records
        self.filteredRecords = filteredRecords
    }

    var body: some View {
        Table(filteredRecords) {
            TableColumn("Key", value: \.key)
            TableColumn("Type") { record in
                return Text(verbatim: record.value.typeName)
            }
            TableColumn("Value") { record in
                switch record.value {
                case .boolean(let value):
                    Toggle(isOn: .constant(value)) {
                        EmptyView()
                    }
                    .toggleStyle(SwitchToggleStyle())
                case .integer(let value):
                    Text(value, format: .number).monospacedDigit()
                case .float(let value):
                    Text(value, format: .number).monospacedDigit()
                case .string(let value):
                    Text(verbatim: value)
                case .array(let value):
                    ArrayView(array: value)
                case .dictionary(let value):
                    Text(verbatim: String(describing: value))
                case .data(let value):
                    Text("\(value.count) bytes")
                case .date(let value):
                    Text(value, style: .date)
                case .unknown(let value):
                    Text(verbatim: String(describing: value))
                }
            }
        }
        .searchable(text: $searchText)
        .onChange(of: searchText) { searchText in
            let pattern = Regex { searchText }.ignoresCase()
            let filteredRecords = records
                .filter { record in
                    if searchText.isEmpty {
                        return true
                    }
                    return record.key.contains(pattern)
                    || String(describing: record.value).contains(pattern)
                }
                .sorted(using: MySortComparator(\.key))

            self.filteredRecords = filteredRecords
        }
    }
}

struct ArrayView: View {
    let array: [Any]

    var body: some View {
        let array = Array(array.enumerated())
        LazyVStack(alignment: .leading) {
            ForEach(array, id: \.0) { element in
                Text(verbatim: String(describing: element.1))
            }
        }
    }
}

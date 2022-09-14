import Foundation
@_implementationOnly import os

private let logger = Logger(subsystem: "TODO", category: "TODO")

class MiniDatabase<Value: Codable> {
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
            values[key]
        }
        set {
            values[key] = newValue
            let record: Record
            if let newValue = newValue {
                record = .set(key, newValue)
            } else {
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
                case let .set(key, value):
                    values[key] = value
                case let .delete(key):
                    values[key] = nil
                case let .snapshot(values):
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
        journal = try FileHandle(forWritingTo: url)
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
            } catch {
                logger.error("Failed to write: \(error)")
            }
        }
    }
}

extension MiniDatabase: ObservableObject {}

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
    func index(after _: Index) -> Index {
        fatalError()
    }

    subscript(_: Index) -> Element {
        _read {
            fatalError()
        }
    }

    typealias Element = (Key, Value)

    struct Index: Comparable {
        static func < (_: Self, _: Self) -> Bool {
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
    func index(before _: Index) -> Index {
        fatalError()
    }
}

extension MiniDatabase: RandomAccessCollection {}

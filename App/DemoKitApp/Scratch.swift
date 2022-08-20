@_spi(DemoKit) import DemoKit
import SwiftUI
@_implementationOnly import RegexBuilder

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
        let records = items.enumerated().map { index, item in
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
            case let o as [Any]:
                value = .array(o)
            case let o as [String: Any]:
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
                Text(verbatim: record.value.typeName)
            }
            TableColumn("Value") { record in
                switch record.value {
                case let .boolean(value):
                    Toggle(isOn: .constant(value)) {
                        EmptyView()
                    }
                    .toggleStyle(SwitchToggleStyle())
                case let .integer(value):
                    Text(value, format: .number).monospacedDigit()
                case let .float(value):
                    Text(value, format: .number).monospacedDigit()
                case let .string(value):
                    Text(verbatim: value)
                case let .array(value):
                    ArrayView(array: value)
                case let .dictionary(value):
                    Text(verbatim: String(describing: value))
                case let .data(value):
                    Text("\(value.count) bytes")
                case let .date(value):
                    Text(value, style: .date)
                case let .unknown(value):
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

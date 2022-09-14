//@propertyWrapper
//
//
//public struct AppStorage<Value> : DynamicProperty {
//    public var wrappedValue: Value { get nonmutating set }
//    public var projectedValue: Binding<Value> { get }
//}
//
//@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
//extension AppStorage {
//    public init(wrappedValue: Value, _ key: String, store: UserDefaults? = nil) where Value == Bool
//    public init(wrappedValue: Value, _ key: String, store: UserDefaults? = nil) where Value == Int
//    public init(wrappedValue: Value, _ key: String, store: UserDefaults? = nil) where Value == Double
//    public init(wrappedValue: Value, _ key: String, store: UserDefaults? = nil) where Value == String
//    public init(wrappedValue: Value, _ key: String, store: UserDefaults? = nil) where Value == URL
//    public init(wrappedValue: Value, _ key: String, store: UserDefaults? = nil) where Value == Data
//    public init(wrappedValue: Value, _ key: String, store: UserDefaults? = nil) where Value : RawRepresentable, Value.RawValue == Int
//    public init(wrappedValue: Value, _ key: String, store: UserDefaults? = nil) where Value : RawRepresentable, Value.RawValue == String
//}
//
//extension AppStorage where Value : ExpressibleByNilLiteral {
//    public init(_ key: String, store: UserDefaults? = nil) where Value == Bool?
//    public init(_ key: String, store: UserDefaults? = nil) where Value == Int?
//    public init(_ key: String, store: UserDefaults? = nil) where Value == Double?
//    public init(_ key: String, store: UserDefaults? = nil) where Value == String?
//    public init(_ key: String, store: UserDefaults? = nil) where Value == URL?
//    public init(_ key: String, store: UserDefaults? = nil) where Value == Data?
//}
//
//extension AppStorage {
//    public init<R>(_ key: String, store: UserDefaults? = nil) where Value == R?, R : RawRepresentable, R.RawValue == String
//    public init<R>(_ key: String, store: UserDefaults? = nil) where Value == R?, R : RawRepresentable, R.RawValue == Int
//}

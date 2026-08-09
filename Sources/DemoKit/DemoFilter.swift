import Foundation

/// Sidebar filtering rules, kept separate from the view so they can be tested directly.
enum DemoFilter {
    static func matches(_ metadata: DemoMetadata, searchText: String, keyword: String?) -> Bool {
        matchesKeyword(metadata, keyword: keyword) && matchesSearch(metadata, searchText: searchText)
    }

    static func matchesKeyword(_ metadata: DemoMetadata, keyword: String?) -> Bool {
        guard let keyword else { return true }
        return metadata.keywords.contains { $0.caseInsensitiveCompare(keyword) == .orderedSame }
    }

    static func matchesSearch(_ metadata: DemoMetadata, searchText: String) -> Bool {
        guard !searchText.isEmpty else { return true }
        let needle = searchText.lowercased()
        return metadata.name.lowercased().contains(needle)
            || (metadata.description?.lowercased().contains(needle) ?? false)
            || (metadata.longDescription?.lowercased().contains(needle) ?? false)
            || metadata.keywords.contains { $0.lowercased().contains(needle) }
    }
}

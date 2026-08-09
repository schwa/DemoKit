@testable import DemoKit
import Testing

private let metadata = DemoMetadata(
    name: "Grass Sphere",
    description: "A furry ball",
    keywords: ["metal", "Geometry"]
)

@Test func keywordFilterMatchesCaseInsensitively() {
    #expect(DemoFilter.matches(metadata, searchText: "", keyword: "geometry"))
    #expect(DemoFilter.matches(metadata, searchText: "", keyword: "Metal"))
}

@Test func keywordFilterRejectsUnrelatedKeyword() {
    #expect(!DemoFilter.matches(metadata, searchText: "", keyword: "audio"))
}

@Test func noKeywordMatchesEverything() {
    #expect(DemoFilter.matches(metadata, searchText: "", keyword: nil))
}

@Test func searchAndKeywordCombine() {
    #expect(DemoFilter.matches(metadata, searchText: "furry", keyword: "metal"))
    #expect(!DemoFilter.matches(metadata, searchText: "furry", keyword: "audio"))
    #expect(!DemoFilter.matches(metadata, searchText: "nothing", keyword: "metal"))
}

@testable import DemoKit
import Foundation
import SwiftUI
import Testing

@Test func defaultsWhenNoQueryItems() {
    let options = ScreenshotOptions.parse(from: URL(string: "x-demo://screenshot")!)
    #expect(options == ScreenshotOptions())
    #expect(options.width == 800)
    #expect(options.height == 600)
    #expect(options.scale == 2)
    #expect(options.format == .png)
    #expect(options.reveal)
    #expect(options.destination == nil)
}

@Test func parsesSizeScaleAndFormat() {
    let url = URL(string: "x-demo://screenshot?width=1200&height=800&scale=3&format=jpg")!
    let options = ScreenshotOptions.parse(from: url)
    #expect(options.width == 1_200)
    #expect(options.height == 800)
    #expect(options.scale == 3)
    #expect(options.format == .jpg)
}

@Test func treatsJpegAsJpg() {
    let options = ScreenshotOptions.parse(from: URL(string: "x-demo://screenshot?format=JPEG")!)
    #expect(options.format == .jpg)
}

@Test func ignoresInvalidValues() {
    let url = URL(string: "x-demo://screenshot?width=abc&scale=-1&format=tiff")!
    let options = ScreenshotOptions.parse(from: url)
    #expect(options.width == 800)
    #expect(options.scale == 2)
    #expect(options.format == .png)
}

@Test func parsesRevealAndBackground() {
    let options = ScreenshotOptions.parse(from: URL(string: "x-demo://screenshot?reveal=false&background=clear")!)
    #expect(!options.reveal)
    #expect(options.background == Color.clear)
}

@Test func parsesHexBackground() {
    let options = ScreenshotOptions.parse(from: URL(string: "x-demo://screenshot?background=%23FF8000")!)
    #expect(options.background == Color(red: 1, green: 128.0 / 255, blue: 0))
}

@Test func destinationDirectoryGetsGeneratedFilename() {
    let options = ScreenshotOptions.parse(from: URL(string: "x-demo://screenshot?destination=/tmp/shots")!)
    #expect(options.fileURL(demoID: "pulse").path == "/tmp/shots/DemoKit-pulse.png")
}

@Test func destinationFileIsUsedVerbatim() {
    let options = ScreenshotOptions.parse(from: URL(string: "x-demo://screenshot?destination=/tmp/out.jpg&format=jpg")!)
    #expect(options.fileURL(demoID: "pulse").path == "/tmp/out.jpg")
}

@Test func defaultDestinationIsTemporaryDirectory() {
    let options = ScreenshotOptions()
    let expected = FileManager.default.temporaryDirectory.appendingPathComponent("DemoKit-pulse.png")
    #expect(options.fileURL(demoID: "pulse") == expected)
}

@MainActor
@Test func screenshotURLPopulatesRequestOnViewModel() {
    let viewModel = DemoPickerViewModel(demos: [])
    viewModel.handleURL(URL(string: "x-demo://screenshot?width=100&format=jpg")!, urlScheme: "x-demo")
    #expect(viewModel.screenshotRequest?.width == 100)
    #expect(viewModel.screenshotRequest?.format == .jpg)
}

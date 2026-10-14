import SwiftUI

@MainActor
enum ScreenshotCapture {
    static func capture<V: View>(_ view: V, demoID: String, options: ScreenshotOptions) {
        let renderer = ImageRenderer(
            content: view
                .frame(width: options.width, height: options.height)
                .background(options.background)
        )
        renderer.scale = options.scale
        guard let data = encodedImage(from: renderer, format: options.format) else {
            logger?.warning("Failed to render screenshot for \(demoID)")
            return
        }
        let url = options.fileURL(demoID: demoID)
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url)
            logger?.info("Screenshot saved to \(url.path)")
            if options.reveal {
                reveal(url)
            }
        } catch {
            logger?.warning("Failed to write screenshot: \(error.localizedDescription)")
        }
    }

    #if os(macOS)
    private static func encodedImage<V: View>(from renderer: ImageRenderer<V>, format: ScreenshotOptions.Format) -> Data? {
        let fileType: NSBitmapImageRep.FileType = format == .jpg ? .jpeg : .png
        guard let tiffData = renderer.nsImage?.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: fileType, properties: [:])
    }

    private static func reveal(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    #elseif os(iOS)
    private static func encodedImage<V: View>(from renderer: ImageRenderer<V>, format: ScreenshotOptions.Format) -> Data? {
        guard let image = renderer.uiImage else { return nil }
        return format == .jpg ? image.jpegData(compressionQuality: 0.9) : image.pngData()
    }

    private static func reveal(_ url: URL) {
        let windowScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        guard var presenter = windowScene?.keyWindow?.rootViewController else {
            logger?.warning("No view controller to present the screenshot share sheet from")
            return
        }
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        let activityController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let popover = activityController.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        presenter.present(activityController, animated: true)
    }
    #else
    private static func encodedImage<V: View>(from _: ImageRenderer<V>, format _: ScreenshotOptions.Format) -> Data? {
        nil
    }

    private static func reveal(_: URL) {}
    #endif
}

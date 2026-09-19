import CoreImage

nonisolated enum LivePhotoFrameRenderer {
    /// Finite edge extension lets neighborhood filters sample real edge colors.
    /// Keep the graph finite because the Grade masks use the image extent.
    static func filterInput(_ source: CIImage) -> CIImage {
        source.cropped(to: completePixelBounds(source.extent)).clampedToExtent()
            .cropped(to: source.extent.insetBy(dx: -16, dy: -16).integral)
    }

    /// H.264/HEVC motion output must cover every pixel, including any rounding
    /// difference between a crop and the compositor's requested render size.
    static func output(_ image: CIImage, renderSize: CGSize) -> CIImage {
        let target = CGRect(origin: .zero, size: renderSize)
        return image.cropped(to: completePixelBounds(image.extent)).clampedToExtent()
            .cropped(to: target)
            .unpremultiplyingAlpha()
            .settingAlphaOne(in: target)
            .cropped(to: target)
    }

    static func encoderSize(_ size: CGSize) -> CGSize {
        CGSize(width: max(2, floor(size.width / 2) * 2),
               height: max(2, floor(size.height / 2) * 2))
    }

    private static func completePixelBounds(_ extent: CGRect) -> CGRect {
        // Fractional crop boundaries contain partially covered pixels. Extend
        // the nearest complete pixel instead of repeating that transparent seam.
        let x = ceil(extent.minX)
        let y = ceil(extent.minY)
        let width = floor(extent.maxX) - x
        let height = floor(extent.maxY) - y
        guard width > 0, height > 0 else { return extent }
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

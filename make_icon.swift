import Cocoa

func makeIcon(size: CGFloat, emoji: String, bgColor: NSColor, cornerRadiusRatio: CGFloat, outputPath: String) {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    // 배경 (둥근 사각형)
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let radius = size * cornerRadiusRatio
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    bgColor.setFill()
    path.fill()

    // 이모지
    let fontSize = size * 0.72
    let font = NSFont(name: "Apple Color Emoji", size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .paragraphStyle: paragraphStyle,
    ]
    let str = NSAttributedString(string: emoji, attributes: attrs)
    let textSize = str.size()
    let drawRect = NSRect(
        x: (size - textSize.width) / 2,
        y: (size - textSize.height) / 2 - size * 0.02,
        width: textSize.width,
        height: textSize.height
    )
    str.draw(in: drawRect)

    image.unlockFocus()

    // PNG로 저장
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let pngData = rep.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG for \(outputPath)")
        return
    }
    do {
        try pngData.write(to: URL(fileURLWithPath: outputPath))
        print("✓ \(outputPath)")
    } catch {
        print("Write failed: \(error)")
    }
}

let bg = NSColor(red: 0.99, green: 0.89, blue: 0.92, alpha: 1.0)  // --accent-soft 톤

makeIcon(size: 180, emoji: "🧶", bgColor: bg, cornerRadiusRatio: 0.22, outputPath: "apple-touch-icon.png")
makeIcon(size: 192, emoji: "🧶", bgColor: bg, cornerRadiusRatio: 0.22, outputPath: "icon-192.png")
makeIcon(size: 512, emoji: "🧶", bgColor: bg, cornerRadiusRatio: 0.22, outputPath: "icon-512.png")
makeIcon(size: 32,  emoji: "🧶", bgColor: bg, cornerRadiusRatio: 0.20, outputPath: "favicon-32.png")

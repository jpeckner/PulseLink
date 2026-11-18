// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

// Makes the Debug and Profile app icons from the Release one, so the three
// builds can be told apart when installed side by side (see "Running" in the
// README): Release keeps its white background, Profile gets green and Debug
// grey.
//
// Run from the repo root after changing the Release icon:
//   swift tool/make_build_icons.swift
//
// It reads the Release iPhone icon (the logo on white) and writes:
//   - ios/Runner/Assets.xcassets/AppIcon-{Debug,Profile}.appiconset/
//   - ios/PulseLinkWatch/Assets.xcassets/AppIcon-{Debug,Profile}.appiconset/
//   - android/app/src/main/res/mipmap-*/ic_launcher_foreground.png: the logo
//     alone, for Debug's and Profile's adaptive icons, whose background
//     colours are in android/app/src/{debug,profile}/res/values/.
//
// The background is replaced by flood-filling the white from the edges.
// Anti-aliased edge pixels are a blend of the logo and white; each is
// re-blended with the new colour, so no white fringe is left.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct RGB {
  var red: Double
  var green: Double
  var blue: Double

  static let white = RGB(red: 255, green: 255, blue: 255)

  init(red: Double, green: Double, blue: Double) {
    self.red = red
    self.green = green
    self.blue = blue
  }

  init(hex: UInt32) {
    self.init(
      red: Double((hex >> 16) & 0xFF),
      green: Double((hex >> 8) & 0xFF),
      blue: Double(hex & 0xFF)
    )
  }

  static func + (lhs: RGB, rhs: RGB) -> RGB {
    RGB(red: lhs.red + rhs.red, green: lhs.green + rhs.green, blue: lhs.blue + rhs.blue)
  }

  static func - (lhs: RGB, rhs: RGB) -> RGB {
    RGB(red: lhs.red - rhs.red, green: lhs.green - rhs.green, blue: lhs.blue - rhs.blue)
  }

  static func * (lhs: RGB, rhs: Double) -> RGB {
    RGB(red: lhs.red * rhs, green: lhs.green * rhs, blue: lhs.blue * rhs)
  }

  func dot(_ other: RGB) -> Double {
    red * other.red + green * other.green + blue * other.blue
  }
}

/// An image as straight (not premultiplied) RGBA bytes.
struct Bitmap {
  let width: Int
  let height: Int
  var pixels: [UInt8]

  init(width: Int, height: Int) {
    self.width = width
    self.height = height
    pixels = [UInt8](repeating: 0, count: width * height * 4)
  }

  func rgb(_ x: Int, _ y: Int) -> RGB {
    let index = (y * width + x) * 4
    return RGB(
      red: Double(pixels[index]),
      green: Double(pixels[index + 1]),
      blue: Double(pixels[index + 2])
    )
  }

  mutating func set(_ x: Int, _ y: Int, _ color: RGB, alpha: Double = 1) {
    let index = (y * width + x) * 4
    func byte(_ value: Double) -> UInt8 { UInt8(max(0, min(255, value.rounded()))) }
    pixels[index] = byte(color.red)
    pixels[index + 1] = byte(color.green)
    pixels[index + 2] = byte(color.blue)
    pixels[index + 3] = byte(alpha * 255)
  }
}

enum IconError: Error {
  case unreadable(String)
  case unwritable(String)
}

func load(_ path: String) throws -> Bitmap {
  guard
    let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
    let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
  else {
    throw IconError.unreadable(path)
  }
  var bitmap = Bitmap(width: image.width, height: image.height)
  // The source is opaque, so premultiplied and straight are the same.
  let drawn = bitmap.pixels.withUnsafeMutableBytes { bytes -> Bool in
    guard
      let context = CGContext(
        data: bytes.baseAddress,
        width: image.width,
        height: image.height,
        bitsPerComponent: 8,
        bytesPerRow: image.width * 4,
        space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
    else {
      return false
    }
    context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    return true
  }
  guard drawn else {
    throw IconError.unreadable(path)
  }
  return bitmap
}

/// Writes [bitmap] as a PNG of [size] pixels square, with the bitmap scaled
/// into the middle [fraction] of it.
func save(_ bitmap: Bitmap, to path: String, size: Int, fraction: Double = 1) throws {
  let space = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
  var premultiplied = bitmap.pixels
  for index in stride(from: 0, to: premultiplied.count, by: 4) {
    let alpha = Double(premultiplied[index + 3]) / 255
    for channel in 0..<3 {
      premultiplied[index + channel] = UInt8((Double(premultiplied[index + channel]) * alpha).rounded())
    }
  }
  let image = premultiplied.withUnsafeMutableBytes { bytes -> CGImage? in
    CGContext(
      data: bytes.baseAddress,
      width: bitmap.width,
      height: bitmap.height,
      bitsPerComponent: 8,
      bytesPerRow: bitmap.width * 4,
      space: space,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )?.makeImage()
  }
  guard
    let image,
    let context = CGContext(
      data: nil,
      width: size,
      height: size,
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: space,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )
  else {
    throw IconError.unwritable(path)
  }
  context.interpolationQuality = .high
  let side = Double(size) * fraction
  let inset = (Double(size) - side) / 2
  context.draw(image, in: CGRect(x: inset, y: inset, width: side, height: side))
  guard
    let scaled = context.makeImage(),
    let destination = CGImageDestinationCreateWithURL(
      URL(fileURLWithPath: path) as CFURL,
      UTType.png.identifier as CFString,
      1,
      nil
    )
  else {
    throw IconError.unwritable(path)
  }
  CGImageDestinationAddImage(destination, scaled, nil)
  guard CGImageDestinationFinalize(destination) else {
    throw IconError.unwritable(path)
  }
}

/// How each pixel of the logo-on-white icon relates to the background.
struct Analysis {
  /// True for the white background, found by flood fill from the edges.
  var isBackground: [Bool]

  /// For each pixel, how much of it is logo (1) rather than white (0), and
  /// the logo colour it's blended from.
  var coverage: [Double]
  var logoColor: [RGB]
}

func analyze(_ bitmap: Bitmap) -> Analysis {
  let width = bitmap.width
  let height = bitmap.height
  let count = width * height
  func isWhite(_ x: Int, _ y: Int) -> Bool {
    let color = bitmap.rgb(x, y)
    return min(color.red, color.green, color.blue) >= 250
  }

  var isBackground = [Bool](repeating: false, count: count)
  var stack: [(Int, Int)] = []
  for x in 0..<width {
    stack.append((x, 0))
    stack.append((x, height - 1))
  }
  for y in 0..<height {
    stack.append((0, y))
    stack.append((width - 1, y))
  }
  while let (x, y) = stack.popLast() {
    let index = y * width + x
    if isBackground[index] || !isWhite(x, y) {
      continue
    }
    isBackground[index] = true
    if x > 0 { stack.append((x - 1, y)) }
    if x < width - 1 { stack.append((x + 1, y)) }
    if y > 0 { stack.append((x, y - 1)) }
    if y < height - 1 { stack.append((x, y + 1)) }
  }

  // Logo pixels within `band` of the background are edge pixels, blended
  // with white; the rest are solid logo.
  let band = 3
  var isEdge = [Bool](repeating: false, count: count)
  for y in 0..<height {
    for x in 0..<width where !isBackground[y * width + x] {
      search: for dy in -band...band {
        for dx in -band...band {
          let nx = x + dx
          let ny = y + dy
          if nx >= 0, ny >= 0, nx < width, ny < height, isBackground[ny * width + nx] {
            isEdge[y * width + x] = true
            break search
          }
        }
      }
    }
  }

  var coverage = [Double](repeating: 0, count: count)
  var logoColor = [RGB](repeating: .white, count: count)
  let reach = band + 2
  for y in 0..<height {
    for x in 0..<width {
      let index = y * width + x
      if isBackground[index] {
        continue
      }
      let pixel = bitmap.rgb(x, y)
      guard isEdge[index] else {
        coverage[index] = 1
        logoColor[index] = pixel
        continue
      }
      // The logo colour nearby: the average of the solid pixels around it.
      // At a sharp corner the nearest solid pixels are further away, so the
      // search widens until it finds some.
      var sum = RGB(red: 0, green: 0, blue: 0)
      var found = 0.0
      var radius = reach
      while found == 0, radius <= 8 * reach {
        for dy in -radius...radius {
          for dx in -radius...radius {
            let nx = x + dx
            let ny = y + dy
            let neighbour = ny * width + nx
            if nx >= 0, ny >= 0, nx < width, ny < height, !isBackground[neighbour],
              !isEdge[neighbour]
            {
              sum = sum + bitmap.rgb(nx, ny)
              found += 1
            }
          }
        }
        radius *= 2
      }
      let logo = found > 0 ? sum * (1 / found) : pixel
      let span = logo - .white
      let length = span.dot(span)
      let amount = length > 1 ? (pixel - .white).dot(span) / length : 1
      coverage[index] = max(0, min(1, amount))
      logoColor[index] = logo
    }
  }
  return Analysis(isBackground: isBackground, coverage: coverage, logoColor: logoColor)
}

/// The icon with its white background replaced by [background]; or, with no
/// background, the logo alone on transparent.
func recolor(_ bitmap: Bitmap, _ analysis: Analysis, background: RGB?) -> Bitmap {
  var result = Bitmap(width: bitmap.width, height: bitmap.height)
  for y in 0..<bitmap.height {
    for x in 0..<bitmap.width {
      let index = y * bitmap.width + x
      let amount = analysis.isBackground[index] ? 0 : analysis.coverage[index]
      let pixel = bitmap.rgb(x, y)
      if let background {
        // pixel = amount * logo + (1 - amount) * white, so swapping the white
        // for the background keeps the logo's share of the blend.
        result.set(x, y, pixel + (background - .white) * (1 - amount))
      } else {
        let color = amount >= 1 ? pixel : analysis.logoColor[index]
        result.set(x, y, color, alpha: amount)
      }
    }
  }
  return result
}

func writeIconSet(_ bitmap: Bitmap, folder: String, platform: String) throws {
  try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
  try save(bitmap, to: "\(folder)/AppIcon.png", size: 1024)
  let contents = """
    {
      "images" : [
        {
          "filename" : "AppIcon.png",
          "idiom" : "universal",
          "platform" : "\(platform)",
          "size" : "1024x1024"
        }
      ],
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }

    """
  try contents.write(toFile: "\(folder)/Contents.json", atomically: true, encoding: .utf8)
}

let source = "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"
let builds: [(name: String, background: RGB)] = [
  // Apple's systemGray (light): dark enough to tell from Release's white.
  ("Debug", RGB(hex: 0x8E8E93)),
  // Apple's systemGreen, in its darker high-contrast (accessible) form.
  ("Profile", RGB(hex: 0x248A3D)),
]

do {
  let icon = try load(source)
  let analysis = analyze(icon)
  for build in builds {
    let recolored = recolor(icon, analysis, background: build.background)
    try writeIconSet(
      recolored,
      folder: "ios/Runner/Assets.xcassets/AppIcon-\(build.name).appiconset",
      platform: "ios"
    )
    try writeIconSet(
      recolored,
      folder: "ios/PulseLinkWatch/Assets.xcassets/AppIcon-\(build.name).appiconset",
      platform: "watchos"
    )
  }
  // An adaptive icon's foreground is 108dp square, of which launchers show
  // about the middle 72dp, so the whole Release icon goes in that middle.
  let logo = recolor(icon, analysis, background: nil)
  let densities = [("mdpi", 1.0), ("hdpi", 1.5), ("xhdpi", 2.0), ("xxhdpi", 3.0), ("xxxhdpi", 4.0)]
  for (density, scale) in densities {
    try save(
      logo,
      to: "android/app/src/main/res/mipmap-\(density)/ic_launcher_foreground.png",
      size: Int(108 * scale),
      fraction: 72.0 / 108.0
    )
  }
  print("Wrote the Debug and Profile icons.")
} catch {
  FileHandle.standardError.write(Data("Couldn't make the icons: \(error)\n".utf8))
  exit(1)
}

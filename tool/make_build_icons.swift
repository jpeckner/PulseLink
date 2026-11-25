// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

// Draws PulseLink's app icon, a red heart with a white ECG trace, and writes
// every icon the apps use from it. Each build has its own background, so the
// three can be told apart when installed side by side (see "Running" in the
// README): Release white, Profile green and Debug grey.
//
// Run from the repo root after changing the design or a colour below:
//   swift tool/make_build_icons.swift
//
// It writes:
//   - ios/Runner/AppIcon.icon/: the Release iPhone icon, an Icon Composer
//     document with a white background, the heart and the trace as layers,
//     so iOS can draw its Dark, Clear and Tinted appearances from them.
//   - ios/Runner/Assets.xcassets/AppIcon-{Debug,Profile}.appiconset/
//   - ios/PulseLinkWatch/Assets.xcassets/AppIcon{,-Debug,-Profile}.appiconset/
//   - android/app/src/main/res/mipmap-*/ic_launcher_foreground.png: the heart
//     and trace alone, for every build's adaptive icon. Release's background
//     is in src/main/res/mipmap-anydpi/ic_launcher.xml; Debug's and
//     Profile's are in src/{debug,profile}/res/values/.
//   - android/app/src/main/res/mipmap-*/ic_launcher_monochrome.png: the heart
//     with the trace cut out, for Release's themed icon.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct RGB {
  /// Each from 0 to 255.
  var red: Int
  var green: Int
  var blue: Int

  init(hex: Int) {
    red = (hex >> 16) & 0xFF
    green = (hex >> 8) & 0xFF
    blue = hex & 0xFF
  }

  var cgColor: CGColor {
    CGColor(
      srgbRed: CGFloat(red) / 255,
      green: CGFloat(green) / 255,
      blue: CGFloat(blue) / 255,
      alpha: 1
    )
  }

  /// As SVG writes it, such as `#E5394B`.
  var svg: String { String(format: "#%02X%02X%02X", red, green, blue) }

  /// As Icon Composer's icon.json writes it.
  var iconComposer: String {
    String(
      format: "srgb:%.5f,%.5f,%.5f,1.00000",
      Double(red) / 255,
      Double(green) / 255,
      Double(blue) / 255
    )
  }
}

enum Palette {
  static let heart = RGB(hex: 0xE5394B)
  static let trace = RGB(hex: 0xFFFFFF)
  /// The Release icon's background in Dark mode, with the trace drawn in it
  /// too, so the trace looks cut out of the heart: Apple's systemGray6
  /// (dark).
  static let darkBackground = RGB(hex: 0x1C1C1E)
}

/// The icon's design, on a canvas of `Design.canvas` points square with y
/// pointing down, as in SVG.
enum Design {
  static let canvas = 1024.0

  enum Segment {
    case move(CGPoint)
    case curve(CGPoint, CGPoint, to: CGPoint)
    case close
  }

  static let heart: [Segment] = [
    .move(CGPoint(x: 512, y: 852)),
    .curve(CGPoint(x: 512, y: 852), CGPoint(x: 160, y: 640), to: CGPoint(x: 160, y: 400)),
    .curve(CGPoint(x: 160, y: 268), CGPoint(x: 262, y: 176), to: CGPoint(x: 380, y: 176)),
    .curve(CGPoint(x: 446, y: 176), CGPoint(x: 488, y: 210), to: CGPoint(x: 512, y: 252)),
    .curve(CGPoint(x: 536, y: 210), CGPoint(x: 578, y: 176), to: CGPoint(x: 644, y: 176)),
    .curve(CGPoint(x: 762, y: 176), CGPoint(x: 864, y: 268), to: CGPoint(x: 864, y: 400)),
    .curve(CGPoint(x: 864, y: 640), CGPoint(x: 512, y: 852), to: CGPoint(x: 512, y: 852)),
    .close,
  ]

  /// The ECG trace: a line through these points, with round caps and joins.
  static let trace: [CGPoint] = [
    CGPoint(x: 232, y: 480),
    CGPoint(x: 384, y: 480),
    CGPoint(x: 432, y: 410),
    CGPoint(x: 484, y: 580),
    CGPoint(x: 548, y: 296),
    CGPoint(x: 604, y: 540),
    CGPoint(x: 640, y: 480),
    CGPoint(x: 792, y: 480),
  ]
  static let traceWidth = 50.0

  static var heartPath: CGPath {
    let path = CGMutablePath()
    for segment in heart {
      switch segment {
      case .move(let point):
        path.move(to: point)
      case .curve(let control1, let control2, let end):
        path.addCurve(to: end, control1: control1, control2: control2)
      case .close:
        path.closeSubpath()
      }
    }
    return path
  }

  static var tracePath: CGPath {
    let path = CGMutablePath()
    path.addLines(between: trace)
    return path
  }

  static var heartSVG: String {
    func format(_ point: CGPoint) -> String { "\(Int(point.x)) \(Int(point.y))" }
    let data = heart.map { segment in
      switch segment {
      case .move(let point):
        "M\(format(point))"
      case .curve(let control1, let control2, let end):
        "C\(format(control1)) \(format(control2)) \(format(end))"
      case .close:
        "Z"
      }
    }
    return svg(
      #"<path fill="\#(Palette.heart.svg)" d="\#(data.joined(separator: " "))"/>"#
    )
  }

  static var traceSVG: String {
    let points = trace.map { "\(Int($0.x)),\(Int($0.y))" }.joined(separator: " ")
    return svg(
      #"<polyline fill="none" stroke="\#(Palette.trace.svg)" stroke-width="\#(Int(traceWidth))" "#
        + #"stroke-linecap="round" stroke-linejoin="round" points="\#(points)"/>"#
    )
  }

  private static func svg(_ body: String) -> String {
    let side = Int(canvas)
    return #"<svg xmlns="http://www.w3.org/2000/svg" width="\#(side)" height="\#(side)" "#
      + #"viewBox="0 0 \#(side) \#(side)">\#(body)</svg>"# + "\n"
  }
}

/// What to draw.
enum Style {
  /// The heart and trace on [background], or on transparent with none. An
  /// icon with a background is opaque, as Apple requires.
  case colour(background: RGB?)

  /// The heart in white with the trace cut out, on transparent: Android's
  /// themed icon, which keeps only the alpha.
  case monochrome
}

enum IconError: Error {
  case unwritable(String)
}

/// Draws [style] into a PNG of [size] pixels square, with the design's
/// canvas scaled into the middle [fraction] of it.
func writePNG(_ style: Style, to path: String, size: Int, fraction: Double = 1) throws {
  let isOpaque =
    switch style {
    case .colour(let background): background != nil
    case .monochrome: false
    }
  guard
    let context = CGContext(
      data: nil,
      width: size,
      height: size,
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: isOpaque
        ? CGImageAlphaInfo.noneSkipLast.rawValue
        : CGImageAlphaInfo.premultipliedLast.rawValue
    )
  else {
    throw IconError.unwritable(path)
  }
  let side = Double(size) * fraction
  let inset = (Double(size) - side) / 2
  // Core Graphics' y points up; flip it to the design's.
  context.translateBy(x: inset, y: Double(size) - inset)
  context.scaleBy(x: side / Design.canvas, y: -side / Design.canvas)

  switch style {
  case .colour(let background):
    if let background {
      context.setFillColor(background.cgColor)
      context.fill(CGRect(x: 0, y: 0, width: Design.canvas, height: Design.canvas))
    }
    context.setFillColor(Palette.heart.cgColor)
    context.addPath(Design.heartPath)
    context.fillPath()
    context.setStrokeColor(Palette.trace.cgColor)
  case .monochrome:
    context.setFillColor(CGColor(gray: 1, alpha: 1))
    context.addPath(Design.heartPath)
    context.fillPath()
    context.setBlendMode(.clear)
  }
  context.setLineWidth(Design.traceWidth)
  context.setLineCap(.round)
  context.setLineJoin(.round)
  context.addPath(Design.tracePath)
  context.strokePath()

  guard
    let image = context.makeImage(),
    let destination = CGImageDestinationCreateWithURL(
      URL(fileURLWithPath: path) as CFURL,
      UTType.png.identifier as CFString,
      1,
      nil
    )
  else {
    throw IconError.unwritable(path)
  }
  CGImageDestinationAddImage(destination, image, nil)
  guard CGImageDestinationFinalize(destination) else {
    throw IconError.unwritable(path)
  }
}

func write(_ text: String, to path: String) throws {
  try text.write(toFile: path, atomically: true, encoding: .utf8)
}

/// An asset catalog app icon of one 1024-pixel image, from which Xcode makes
/// the other sizes.
func writeIconSet(background: RGB, folder: String, platform: String) throws {
  try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
  try writePNG(.colour(background: background), to: "\(folder)/AppIcon.png", size: 1024)
  try write(
    """
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

    """,
    to: "\(folder)/Contents.json"
  )
}

/// An Icon Composer document: a white background with the heart and the
/// trace as layers. In Dark mode the background turns near-black and the
/// trace takes its colour. iOS makes the Clear and Tinted appearances from
/// the layers.
func writeIconComposerDocument(folder: String) throws {
  let assets = "\(folder)/Assets"
  try FileManager.default.createDirectory(atPath: assets, withIntermediateDirectories: true)
  try write(Design.heartSVG, to: "\(assets)/heart.svg")
  try write(Design.traceSVG, to: "\(assets)/trace.svg")
  // Layers are listed top first.
  try write(
    """
    {
      "fill-specializations" : [
        {
          "value" : {
            "solid" : "\(RGB(hex: 0xFFFFFF).iconComposer)"
          }
        },
        {
          "appearance" : "dark",
          "value" : {
            "solid" : "\(Palette.darkBackground.iconComposer)"
          }
        }
      ],
      "groups" : [
        {
          "layers" : [
            {
              "fill-specializations" : [
                {
                  "appearance" : "dark",
                  "value" : {
                    "solid" : "\(Palette.darkBackground.iconComposer)"
                  }
                }
              ],
              "image-name" : "trace.svg",
              "name" : "trace"
            },
            {
              "image-name" : "heart.svg",
              "name" : "heart"
            }
          ]
        }
      ],
      "supported-platforms" : {
        "squares" : [
          "iOS"
        ]
      }
    }

    """,
    to: "\(folder)/icon.json"
  )
}

enum Build: CaseIterable {
  case debug
  case profile
  case release

  /// The asset catalog icon's name: the build's `PULSELINK_APP_ICON` in
  /// Runner.xcodeproj.
  var iconName: String {
    switch self {
    case .debug: "AppIcon-Debug"
    case .profile: "AppIcon-Profile"
    case .release: "AppIcon"
    }
  }

  var background: RGB {
    switch self {
    // Apple's systemGray (light): dark enough to tell from Release's white.
    case .debug: RGB(hex: 0x8E8E93)
    // Apple's systemGreen, in its darker high-contrast (accessible) form.
    case .profile: RGB(hex: 0x248A3D)
    case .release: RGB(hex: 0xFFFFFF)
    }
  }
}

do {
  for build in Build.allCases {
    switch build {
    case .debug, .profile:
      try writeIconSet(
        background: build.background,
        folder: "ios/Runner/Assets.xcassets/\(build.iconName).appiconset",
        platform: "ios"
      )
    case .release:
      try writeIconComposerDocument(folder: "ios/Runner/\(build.iconName).icon")
    }
    // The watch keeps one icon per build, without Icon Composer's appearances.
    try writeIconSet(
      background: build.background,
      folder: "ios/PulseLinkWatch/Assets.xcassets/\(build.iconName).appiconset",
      platform: "watchos"
    )
  }
  // An adaptive icon's layers are 108dp square, of which launchers show
  // about the middle 72dp, so the design's whole canvas goes in that middle.
  let densities = [("mdpi", 1.0), ("hdpi", 1.5), ("xhdpi", 2.0), ("xxhdpi", 3.0), ("xxxhdpi", 4.0)]
  for (density, scale) in densities {
    let folder = "android/app/src/main/res/mipmap-\(density)"
    let size = Int(108 * scale)
    let fraction = 72.0 / 108.0
    try writePNG(
      .colour(background: nil),
      to: "\(folder)/ic_launcher_foreground.png",
      size: size,
      fraction: fraction
    )
    try writePNG(.monochrome, to: "\(folder)/ic_launcher_monochrome.png", size: size, fraction: fraction)
  }
  print("Wrote the app icons.")
} catch {
  FileHandle.standardError.write(Data("Couldn't make the icons: \(error)\n".utf8))
  exit(1)
}

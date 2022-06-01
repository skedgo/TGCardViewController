// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "TGCardViewController",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v13)
  ],
  products: [
    .library(
      name: "TGCardViewController",
      targets: ["TGCardViewController"]),
  ],
  dependencies: [],
  targets: [
    .target(
      name: "TGCardViewController",
      dependencies: []
    )
  ]
)


#if swift(>=5.6)
// Add the documentation compiler plugin if possible
package.dependencies.append(
  .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
)
#endif

// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "TGCardViewController",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v12)
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
      dependencies: [])
  ]
)

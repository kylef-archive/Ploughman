import PackageDescription


let package = Package(
  name: "Ploughman",
  dependencies: [
    .Package(url: "https://github.com/kylef/PathKit", majorVersion: 0),
    .Package(url: "https://github.com/kylef/Commander", majorVersion: 0),
  ]
)

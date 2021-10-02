// swift-tools-version:5.4
import PackageDescription

let package = Package(
    name: "CotEditor",
    defaultLocalization: "en",
    platforms: [ .macOS(.v11) ],
    products: [ 
        .library(name: "CotEditor", targets: ["CotEditor"])
    ],
    dependencies: [
        .package(name: "Yams", url: "https://github.com/jpsim/Yams.git", from: "4.0.6"),
        .package(name: "ColorCode", url: "https://github.com/1024jp/WFColorCode.git", from: "2.7.0"),
    ],
    targets: [
        .target(name: "CotEditor", dependencies: [
            "Yams",
            "ColorCode",
        ],
        exclude: [
        ],
        resources: [
            .process("Resources"),
        ],
        linkerSettings: [
            .linkedFramework("AppKit"),
        ]),
        //.testtarget(name: "coteditortests", 
            // tests not yet working
            //dependencies: [
                //"CotEditor"
            //],
            //path: "Tests",
            //exclude: [
                //"Info.plist",
                //"TestFiles"
            //]
        ////),
    ]
)


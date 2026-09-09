// swift-tools-version: 5.9
import PackageDescription

// This Package.swift declares the SPM dependency only.
// It is NOT used to build the app — you need Xcode to build an iOS app.
// Use this file to identify which package to add in Xcode → File → Add Package Dependencies.

let package = Package(
    name: "Annuli",
    platforms: [.iOS(.v16)],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "Annuli",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
            ]
        ),
    ]
)

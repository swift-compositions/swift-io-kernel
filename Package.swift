// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-io-kernel",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(
            name: "IO Kernel",
            targets: ["IO Kernel"]
        ),
        .library(
            name: "IO Kernel Events",
            targets: ["IO Kernel Events"]
        ),
        .library(
            name: "IO Kernel Completions",
            targets: ["IO Kernel Completions"]
        ),
        .library(
            name: "IO Kernel Test Support",
            targets: ["IO Kernel Test Support"]
        ),
        .library(
            name: "IO Kernel Completions Test Support",
            targets: ["IO Kernel Completions Test Support"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-molecules/swift-async-channel.git", branch: "main"),
        .package(url: "https://github.com/swift-molecules/swift-storage-memory.git", branch: "main"),
        .package(
            url: "https://github.com/swift-compositions/swift-kernel.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-async.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-compositions/swift-executors.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-compositions/swift-threads.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-compositions/swift-synchronizers.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-io.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-buffer.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-heap.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-dictionary.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-hash-table.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-buffer-linear.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-storage.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-memory-allocation.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-memory.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-span-byte.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-either.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-witness.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-compositions/swift-witnesses.git",
            branch: "main"
        ),
    ],
    targets: [

        .target(
            name: "IO Kernel Events",
            dependencies: [
                .product(name: "Kernel", package: "swift-kernel"),
                .product(name: "IO", package: "swift-io"),
                .product(name: "Executors", package: "swift-executors"),
                .product(name: "Async Lifecycle", package: "swift-async"),
                .product(name: "Async Channel", package: "swift-async-channel"),
                .product(name: "Heap Primitive", package: "swift-heap"),
                .product(name: "Buffer", package: "swift-buffer"),
                .product(name: "Memory", package: "swift-memory"),
                .product(name: "Dictionary", package: "swift-dictionary"),
                .product(name: "Witness", package: "swift-witness"),
                .product(name: "Witnesses", package: "swift-witnesses"),
                .product(name: "Either", package: "swift-either"),
            ],
        ),

        .target(
            name: "IO Kernel Completions",
            dependencies: [
                .product(
                    name: "Kernel",
                    package: "swift-kernel"
                ),
                .product(
                    name: "Kernel Completion",
                    package: "swift-kernel"
                ),
                .product(
                    name: "IO",
                    package: "swift-io"
                ),
                .product(
                    name: "Executors",
                    package: "swift-executors"
                ),
                .product(
                    name: "Memory",
                    package: "swift-memory"
                ),
                .product(
                    name: "Dictionary",
                    package: "swift-dictionary"
                ),
                .product(
                    name: "Hash Indexed Primitive",
                    package: "swift-hash-table"
                ),
                .product(
                    name: "Buffer",
                    package: "swift-buffer"
                ),
                .product(
                    name: "Buffer Linear Primitive",
                    package: "swift-buffer-linear"
                ),
                .product(
                    name: "Buffer Linear",
                    package: "swift-buffer-linear"
                ),
                .product(name: "Storage", package: "swift-storage"),
                .product(
                    name: "Storage Memory",
                    package: "swift-storage-memory"
                ),
                .product(
                    name: "Memory Allocator",
                    package: "swift-memory-allocation"
                ),
                .product(name: "Synchronizer Blocking", package: "swift-synchronizers"),
            ]
        ),

        .target(
            name: "IO Kernel",
            dependencies: [
                "IO Kernel Events",
                "IO Kernel Completions",
                .product(name: "Kernel", package: "swift-kernel"),
                .product(name: "IO", package: "swift-io"),
                .product(name: "Either", package: "swift-either"),
            ]
        ),

        .target(
            name: "IO Kernel Test Support",
            dependencies: [
                .product(name: "Span Byte", package: "swift-span-byte"),
                "IO Kernel",
                .product(name: "Kernel", package: "swift-kernel"),
                .product(name: "Kernel Test Support", package: "swift-kernel"),
                .product(name: "IO", package: "swift-io"),
                .product(name: "Thread Actor", package: "swift-threads"),
                .product(name: "Executors", package: "swift-executors"),
                .product(name: "Buffer", package: "swift-buffer"),
                .product(name: "Memory", package: "swift-memory"),
            ],
            path: "Tests/Support"
        ),

        .target(
            name: "IO Kernel Completions Test Support",
            dependencies: [
                "IO Kernel Completions",
                "IO Kernel Events",
                "IO Kernel Test Support",
                .product(name: "Synchronizer Blocking", package: "swift-synchronizers"),
            ],
            path: "Tests/Completions Support"
        ),

        .testTarget(
            name: "IO Kernel Blocking Tests",
            dependencies: [
                "IO Kernel Test Support"
            ],
            path: "Tests/IO Kernel Blocking Tests"
        ),
        .testTarget(
            name: "IO Kernel Completions Tests",
            dependencies: [
                "IO Kernel Completions",
                "IO Kernel Completions Test Support",
            ]
        ),
        .testTarget(
            name: "IO Kernel Tests",
            dependencies: [
                "IO Kernel",
                "IO Kernel Test Support",
            ]
        ),
        .testTarget(
            name: "IO Kernel Events Tests",
            dependencies: [
                .product(name: "Async Channel", package: "swift-async-channel"),
                "IO Kernel Events",
                "IO Kernel Test Support",
            ]
        )
    ]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}

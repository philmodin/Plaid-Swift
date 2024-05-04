// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "PlaidSwift",
	platforms: [
		.macOS(.v11)
	],
    products: [
		.library(
			name: "PlaidClient",
			targets: [
				"PlaidClient",
				// Uncomment the following line to regenerate code from openapi.yml
//				"PlaidClientGenerator"
			]
		),
    ],
	dependencies: [
		.package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.0.0"),
		.package(url: "https://github.com/swift-server/swift-openapi-async-http-client", from: "1.0.0"),
		.package(url: "https://github.com/apple/swift-openapi-generator", from: "1.0.0"),
	],
    targets: [
        .target(
            name: "PlaidClient",
			dependencies: [
				.product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
				.product(name: "OpenAPIAsyncHTTPClient", package: "swift-openapi-async-http-client"),
			]
		),
        .testTarget(
            name: "PlaidClientTests",
            dependencies: ["PlaidClient"]),
		.target(
			name: "PlaidClientGenerator",
			dependencies: [
				.product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
				.product(name: "OpenAPIAsyncHTTPClient", package: "swift-openapi-async-http-client"),
			],
			plugins: [.plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")]
		),
    ]
)

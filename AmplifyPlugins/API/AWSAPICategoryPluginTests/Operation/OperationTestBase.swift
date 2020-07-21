//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPICategoryPlugin

class OperationTestBase: XCTestCase {

    override func setUp() {
        Amplify.reset()
    }

    func setUpPlugin(with factory: URLSessionBehaviorFactory? = nil) {
        let apiPlugin: AWSAPIPlugin

        if let factory = factory {
            apiPlugin = AWSAPIPlugin(sessionFactory: factory)
        } else {
            apiPlugin = AWSAPIPlugin()
        }

        let apiConfig = APICategoryConfiguration(plugins: [
            "awsAPIPlugin": [
                "Valid": [
                    "endpoint": "http://www.example.com",
                    "authorizationType": "API_KEY",
                    "apiKey": "SpecialApiKey33"
                ]
            ]
        ])

        let amplifyConfig = AmplifyConfiguration(api: apiConfig)

        do {
            try Amplify.add(plugin: apiPlugin)
            try Amplify.configure(amplifyConfig)
        } catch {
            continueAfterFailure = false
            XCTFail("Error during setup: \(error)")
        }
    }

}

//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSAPICategoryPlugin
@testable import AmplifyTestCommon

@available(iOS 13.0, *)
class GraphQLCombineTests: AWSAPICategoryPluginTestBase {

    func testQuerySucceeds() {
        XCTFail("Not yet implemented")
    }

    func testQueryFails() {
        XCTFail("Not yet implemented")
    }

    func testQueryCancels() {
        XCTFail("Not yet implemented")
    }

    func testMutateSucceeds() {
        XCTFail("Not yet implemented")
    }

    func testMutateFails() {
        XCTFail("Not yet implemented")
    }

    func testMutateCancels() {
        XCTFail("Not yet implemented")
    }

    func testSubscribeSucceeds() {
        XCTFail("Not yet implemented")
    }

    func testSubscribeFails() {
        XCTFail("Not yet implemented")
    }

    func testSubscribeCancels() {
        let request = GraphQLRequest(apiName: apiName,
                                     document: testDocument,
                                     variables: nil,
                                     responseType: JSONValue.self)

        let receivedFinished = expectation(description: "Received finished")
        let receivedFailure = expectation(description: "Received failure")
        receivedFailure.isInverted = true
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true

        let valueListener: GraphQLSubscriptionOperation<JSONValue>.InProcessListener = { _ in
            receivedValue.fulfill()
        }

        let operation = apiPlugin.subscribe(
            request: request,
            valueListener: valueListener,
            completionListener: nil
        )

        let resultSink = operation
            .resultPublisher
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    receivedFinished.fulfill()
                case .failure:
                    receivedFailure.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        operation.cancel()

        XCTAssert(operation.isCancelled)

        waitForExpectations(timeout: 0.05)
        resultSink.cancel()
    }

}

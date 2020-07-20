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
class GraphQLSubscribeCombineTests: OperationTestBase {
    let testDocument = "subscribe { subscribeTodos { id name description }}"

    func testSubscribeResultSucceeds() throws {
        let testJSONData: JSONValue = ["foo": true]
        let sentData = #"{"data": {"foo": true}}"# .data(using: .utf8)!
        try setUpPluginForSubscriptionResponse()

        let request = GraphQLRequest(document: testDocument, variables: nil, responseType: JSONValue.self)

        let receivedValue = expectation(description: "Received value")
        let receivedResponseError = expectation(description: "Received response error")
        receivedResponseError.isInverted = true
        let receivedFinish = expectation(description: "Received finished")
        let receivedFailure = expectation(description: "Received failed")
        receivedFailure.isInverted = true

        let sink = Amplify.API.subscribe(request: request)
            .resultPublisher
            .sink(
                receiveCompletion: { print($0) },
                receiveValue: { print($0) }
        )

        waitForExpectations(timeout: 0.05)
        sink.cancel()
    }

    func testSubscribeSuccessEvent() {
        XCTFail("Not yet implemented")
    }

    func testSubscribeEventHandlesResponseError() {
        XCTFail("Not yet implemented")
    }

    func testSubscribeResultFails() {
        XCTFail("Not yet implemented")
    }

    func testSubscribeInProcessCancels() {
        XCTFail("Not yet implemented")
    }

    func testSubscribeResultCancels() {
        XCTFail("Not yet implemented")
    }

}

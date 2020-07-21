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
import AppSyncRealTimeClient

@available(iOS 13.0, *)
class GraphQLSubscribeCombineTests: OperationTestBase {
    let testDocument = "subscribe { subscribeTodos { id name description }}"

    func testSubscribeResultSucceeds() throws {
        let testJSONData: JSONValue = ["foo": true]
        let sentData = #"{"data": {"foo": true}}"# .data(using: .utf8)!

        var subscriptionItem: SubscriptionItem!
        var subscriptionEventHandler: SubscriptionEventHandler!

        let onSubscribeInvoked = expectation(description: "onSubscribeInvoked")
        let onSubscribe: MockSubscriptionConnection.OnSubscribe = { requestString, variables, eventHandler in
            let item = SubscriptionItem(
                requestString: requestString,
                variables: variables,
                eventHandler: eventHandler
            )

            subscriptionItem = item
            subscriptionEventHandler = eventHandler

            onSubscribeInvoked.fulfill()
            return item
        }

        let onGetOrCreateConnection: MockSubscriptionConnectionFactory.OnGetOrCreateConnection = { _, _ in
            MockSubscriptionConnection(onSubscribe: onSubscribe, onUnsubscribe: { _ in })
        }

        try setUpPluginForSubscriptionResponse(onGetOrCreateConnection: onGetOrCreateConnection)

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
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        receivedFinish.fulfill()
                    case .failure:
                        receivedFailure.fulfill()
                    }
            }, receiveValue: { value in
                XCTFail("This should publish data, not Void")
                receivedValue.fulfill()
            }
        )

        wait(for: [onSubscribeInvoked], timeout: 0.05)

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.connection(.connected), subscriptionItem)
        subscriptionEventHandler(.data(sentData), subscriptionItem)
        subscriptionEventHandler(.connection(.disconnected), subscriptionItem)

        wait(
            for: [receivedValue, receivedResponseError, receivedFinish, receivedFailure],
            timeout: 0.05
        )

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

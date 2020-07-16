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
class GraphQLCombineTests: OperationTestBase {
    let testDocument = "query { getTodo { id name description }}"

    func testQuerySucceeds() {
        let testJSONData: JSONValue = ["foo": true]
        let sentData = #"{"data": {"foo": true}}"# .data(using: .utf8)!

        var mockTask: MockURLSessionTask!
        mockTask = MockURLSessionTask(onResume: {
            guard let mockSession = mockTask.mockSession,
                let delegate = mockSession.sessionBehaviorDelegate
                else {
                    return
            }

            delegate.urlSessionBehavior(mockSession,
                                        dataTaskBehavior: mockTask,
                                        didReceive: sentData)

            delegate.urlSessionBehavior(mockSession,
                                        dataTaskBehavior: mockTask,
                                        didCompleteWithError: nil)
        })

        guard let task = mockTask else {
            XCTFail("mockTask unexpectedly nil")
            return
        }

        let mockSession = MockURLSession(onTaskForRequest: { _ in task })
        let factory = MockSessionFactory(returning: mockSession)
        setUpPlugin(with: factory, endpointType: .graphQL)

        let request = GraphQLRequest(document: testDocument, variables: nil, responseType: JSONValue.self)

        let receivedValue = expectation(description: "Received value")
        let receivedResponseError = expectation(description: "Received response error")
        receivedResponseError.isInverted = true
        let receivedFinish = expectation(description: "Received finished")
        let receivedFailure = expectation(description: "Received failed")
        receivedFailure.isInverted = true

        let sink = Amplify.API.query(request: request)
            .resultPublisher
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    receivedFailure.fulfill()
                case .finished:
                    receivedFinish.fulfill()
                }
            }, receiveValue: { queryResult in
                switch queryResult {
                case .success(let jsonValue):
                    XCTAssertEqual(jsonValue, testJSONData)
                    receivedValue.fulfill()
                case .failure:
                    receivedResponseError.fulfill()
                }
            })

        waitForExpectations(timeout: 0.05)
        sink.cancel()
    }

    func testResponseError() {
        let sentData = #"{"data": {"foo": true}, "errors": []}"# .data(using: .utf8)!

        var mockTask: MockURLSessionTask!
        mockTask = MockURLSessionTask(onResume: {
            guard let mockSession = mockTask.mockSession,
                let delegate = mockSession.sessionBehaviorDelegate
                else {
                    return
            }

            delegate.urlSessionBehavior(mockSession,
                                        dataTaskBehavior: mockTask,
                                        didReceive: sentData)

            delegate.urlSessionBehavior(mockSession,
                                        dataTaskBehavior: mockTask,
                                        didCompleteWithError: nil)
        })

        guard let task = mockTask else {
            XCTFail("mockTask unexpectedly nil")
            return
        }

        let mockSession = MockURLSession(onTaskForRequest: { _ in task })
        let factory = MockSessionFactory(returning: mockSession)
        setUpPlugin(with: factory, endpointType: .graphQL)

        let request = GraphQLRequest(document: testDocument, variables: nil, responseType: JSONValue.self)

        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedResponseError = expectation(description: "Received response error")
        let receivedFinish = expectation(description: "Received finished")
        let receivedFailure = expectation(description: "Received failed")
        receivedFailure.isInverted = true

        let sink = Amplify.API.query(request: request)
            .resultPublisher
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    receivedFailure.fulfill()
                case .finished:
                    receivedFinish.fulfill()
                }
            }, receiveValue: { queryResult in
                switch queryResult {
                case .success:
                    receivedValue.fulfill()
                case .failure:
                    receivedResponseError.fulfill()
                }
            })

        waitForExpectations(timeout: 0.05)
        sink.cancel()

    }

    func testQueryFails() {
        let sentData = #"{"data": {"foo": true}}"# .data(using: .utf8)!

        var mockTask: MockURLSessionTask!
        mockTask = MockURLSessionTask(onResume: {
            guard let mockSession = mockTask.mockSession,
                let delegate = mockSession.sessionBehaviorDelegate
                else {
                    return
            }

            delegate.urlSessionBehavior(mockSession,
                                        dataTaskBehavior: mockTask,
                                        didReceive: sentData)

            delegate.urlSessionBehavior(mockSession,
                                        dataTaskBehavior: mockTask,
                                        didCompleteWithError: URLError(.badServerResponse))
        })

        guard let task = mockTask else {
            XCTFail("mockTask unexpectedly nil")
            return
        }

        let mockSession = MockURLSession(onTaskForRequest: { _ in task })
        let factory = MockSessionFactory(returning: mockSession)
        setUpPlugin(with: factory, endpointType: .graphQL)

        let request = GraphQLRequest(document: testDocument, variables: nil, responseType: JSONValue.self)

        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedResponseError = expectation(description: "Received response error")
        receivedResponseError.isInverted = true
        let receivedFinish = expectation(description: "Received finished")
        receivedFinish.isInverted = true
        let receivedFailure = expectation(description: "Received failed")

        let sink = Amplify.API.query(request: request)
            .resultPublisher
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    receivedFailure.fulfill()
                case .finished:
                    receivedFinish.fulfill()
                }
            }, receiveValue: { queryResult in
                switch queryResult {
                case .success:
                    receivedValue.fulfill()
                case .failure:
                    receivedResponseError.fulfill()
                }
            })

        waitForExpectations(timeout: 0.05)
        sink.cancel()
    }

    func testQueryCancels() {
        let sentData = #"{"data": {"foo": true}}"# .data(using: .utf8)!

        var mockTask: MockURLSessionTask!
        mockTask = MockURLSessionTask(onResume: {
            guard let mockSession = mockTask.mockSession,
                let delegate = mockSession.sessionBehaviorDelegate
                else {
                    return
            }

            delegate.urlSessionBehavior(mockSession,
                                        dataTaskBehavior: mockTask,
                                        didReceive: sentData)

            delegate.urlSessionBehavior(mockSession,
                                        dataTaskBehavior: mockTask,
                                        didCompleteWithError: URLError(.badServerResponse))
        })

        guard let task = mockTask else {
            XCTFail("mockTask unexpectedly nil")
            return
        }

        let mockSession = MockURLSession(onTaskForRequest: { _ in task })
        let factory = MockSessionFactory(returning: mockSession)
        setUpPlugin(with: factory, endpointType: .graphQL)

        let request = GraphQLRequest(document: testDocument, variables: nil, responseType: JSONValue.self)

        let receivedFinish = expectation(description: "Received finished")
        let receivedFailure = expectation(description: "Received failed")
        receivedFailure.isInverted = true

        let operation = Amplify.API.query(request: request)
        let sink = operation
            .resultPublisher
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    receivedFailure.fulfill()
                case .finished:
                    receivedFinish.fulfill()
                }
            }, receiveValue: { _ in })

        operation.cancel()

        waitForExpectations(timeout: 0.05)
        sink.cancel()
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
        XCTFail("Not yet implemented")
    }

}

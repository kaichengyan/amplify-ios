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
class RESTCombineTests: OperationTestBase {

    func testGetSucceeds() {
        let sentData = Data([0x00, 0x01, 0x02, 0x03])

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
        setUpPlugin(with: factory, endpointType: .rest)

        let request = RESTRequest(apiName: "Valid", path: "/path")

        let receivedValue = expectation(description: "Received value")
        let receivedFinish = expectation(description: "Received finished")
        let receivedFailure = expectation(description: "Received failed")
        receivedFailure.isInverted = true

        let sink = Amplify.API.get(request: request)
            .resultPublisher
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    receivedFailure.fulfill()
                case .finished:
                    receivedFinish.fulfill()
                }
            }, receiveValue: { value in
                XCTAssertEqual(value, sentData)
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
        sink.cancel()
    }

    func testGetFails() {
        let sentData = Data([0x00, 0x01, 0x02, 0x03])

        var mockTask: MockURLSessionTask!
        mockTask = MockURLSessionTask(onResume: {
            guard let mockSession = mockTask.mockSession,
                let delegate = mockSession.sessionBehaviorDelegate
                else {
                    return
            }

            delegate.urlSessionBehavior(mockSession,
                                        dataTaskBehavior: mockTask,
                                        didCompleteWithError: URLError.init(.badURL))
        })

        guard let task = mockTask else {
            XCTFail("mockTask unexpectedly nil")
            return
        }

        let mockSession = MockURLSession(onTaskForRequest: { _ in task })
        let factory = MockSessionFactory(returning: mockSession)
        setUpPlugin(with: factory, endpointType: .rest)

        let request = RESTRequest(apiName: "Valid", path: "/path")

        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedFinish = expectation(description: "Received finished")
        receivedFinish.isInverted = true
        let receivedFailure = expectation(description: "Received failed")

        let sink = Amplify.API.get(request: request)
            .resultPublisher
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    receivedFailure.fulfill()
                case .finished:
                    receivedFinish.fulfill()
                }
            }, receiveValue: { value in
                XCTAssertEqual(value, sentData)
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
        sink.cancel()
    }

    func testGetCancels() {
        let sentData = Data([0x00, 0x01, 0x02, 0x03])

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
        setUpPlugin(with: factory, endpointType: .rest)

        let request = RESTRequest(apiName: "Valid", path: "/path")

        let receivedFinish = expectation(description: "Received finished")
        let receivedFailure = expectation(description: "Received failed")
        receivedFailure.isInverted = true

        let operation = Amplify.API.get(request: request)

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

        DispatchQueue.global().async {
            operation.cancel()
        }

        waitForExpectations(timeout: 1.05)
        sink.cancel()
    }

}

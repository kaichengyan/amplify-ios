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

class AWSAPICategoryPluginCombineTests: OperationTestBase {

    func testGetSucceeds() {
        let sentData = Data([0x00, 0x01, 0x02, 0x03])

        var mockTask: MockURLSessionTask?
        mockTask = MockURLSessionTask(onResume: {
            guard let mockTask = mockTask,
                let mockSession = mockTask.mockSession,
                let delegate = mockSession.sessionBehaviorDelegate else {
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
        setUpPlugin(with: factory)

        let callbackInvoked = expectation(description: "Callback was invoked")
        let request = RESTRequest(apiName: "Valid", path: "/path")
        _ = Amplify.API.get(request: request) { event in
            switch event {
            case .success(let data):
                XCTAssertEqual(data, sentData)
            case .failure(let error):
                XCTFail("Unexpected failure: \(error)")
            }
            callbackInvoked.fulfill()
        }

        wait(for: [callbackInvoked], timeout: 1.0)
    }

    func testGetFails() {
        XCTFail("Not yet implemented")
    }

    func testGetCancels() {
        XCTFail("Not yet implemented")
    }

}

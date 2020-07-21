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

    func setUpPlugin(
        sessionFactory: URLSessionBehaviorFactory? = nil,
        subscriptionConnectionFactory: SubscriptionConnectionFactory? = nil,
        endpointType: AWSAPICategoryPluginEndpointType
    ) throws {
        let apiPlugin = AWSAPIPlugin(sessionFactory: sessionFactory)

        let configurationValues: JSONValue = [
            "Valid": [
                "endpointType": .string(endpointType.rawValue),
                "endpoint": "http://www.example.com",
                "authorizationType": "API_KEY",
                "apiKey": "SpecialApiKey33"
            ]
        ]

        let dependencies = try AWSAPIPlugin.ConfigurationDependencies(
            configurationValues: configurationValues,
            authService: MockAWSAuthService(),
            subscriptionConnectionFactory: subscriptionConnectionFactory
        )

        apiPlugin.configure(using: dependencies)

        do {
            // Note that we're configuring Amplify first, then adding the pre-configured plugin. This is a
            // hack to let us assign the mock dependencies to the plugin without having it overwritten by
            // a subsequent call to `Amplify.configure()`.
            // TODO: Refactor plugin configuration to allow dependencies to be passed in at plugin init
            try Amplify.configure(AmplifyConfiguration())
            try Amplify.add(plugin: apiPlugin)
        } catch {
            continueAfterFailure = false
            XCTFail("Error during setup: \(error)")
        }
    }

    func setUpPluginForSingleResponse(
        sending data: Data,
        for endpointType: AWSAPICategoryPluginEndpointType
    ) throws {
        let task = try makeSingleValueSuccessMockTask(sending: data)
        let mockSession = MockURLSession(onTaskForRequest: { _ in task })
        let sessionFactory = MockSessionFactory(returning: mockSession)
        try setUpPlugin(sessionFactory: sessionFactory, endpointType: endpointType)
    }

    func setUpPluginForSingleError(for endpointType: AWSAPICategoryPluginEndpointType) throws {
        let task = try makeSingleValueErrorMockTask()
        let mockSession = MockURLSession(onTaskForRequest: { _ in task })
        let sessionFactory = MockSessionFactory(returning: mockSession)
        try setUpPlugin(sessionFactory: sessionFactory, endpointType: endpointType)
    }

    func setUpPluginForSubscriptionResponse() throws {
        let subscriptionConnectionFactory = MockSubscriptionConnectionFactory()
        try setUpPlugin(
            subscriptionConnectionFactory: subscriptionConnectionFactory,
            endpointType: .graphQL
        )
    }

    func makeSingleValueSuccessMockTask(sending data: Data) throws -> MockURLSessionTask {
        var mockTask: MockURLSessionTask!
        mockTask = MockURLSessionTask(onResume: {
            guard let mockSession = mockTask.mockSession,
                let delegate = mockSession.sessionBehaviorDelegate
                else {
                    return
            }

            delegate.urlSessionBehavior(mockSession,
                                        dataTaskBehavior: mockTask,
                                        didReceive: data)

            delegate.urlSessionBehavior(mockSession,
                                        dataTaskBehavior: mockTask,
                                        didCompleteWithError: nil)
        })

        guard let task = mockTask else {
            throw "mockTask unexpectedly nil"
        }

        return task
    }

    func makeSingleValueErrorMockTask() throws -> MockURLSessionTask {
        var mockTask: MockURLSessionTask!
        mockTask = MockURLSessionTask(onResume: {
            guard let mockSession = mockTask.mockSession,
                let delegate = mockSession.sessionBehaviorDelegate
                else {
                    return
            }

            delegate.urlSessionBehavior(mockSession,
                                        dataTaskBehavior: mockTask,
                                        didCompleteWithError: URLError(.badServerResponse))
        })

        guard let task = mockTask else {
            throw "mockTask unexpectedly nil"
        }

        return task
    }

}

//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSAPICategoryPlugin
import Amplify

import AWSPluginsCore
import AppSyncRealTimeClient

struct MockSubscriptionConnectionFactory: SubscriptionConnectionFactory {

    func getOrCreateConnection(
        for endpointConfig: AWSAPICategoryPluginConfiguration.EndpointConfig,
        authService: AWSAuthServiceBehavior
    ) throws -> SubscriptionConnection {
        fatalError("Not yet implemented")
    }

}

struct MockSubscriptionConnection: SubscriptionConnection {
    func subscribe(
        requestString: String,
        variables: [String: Any?]?,
        eventHandler: @escaping SubscriptionEventHandler
    ) -> SubscriptionItem {
        fatalError("Not yet implemented")
    }

    func unsubscribe(item: SubscriptionItem) {
        fatalError("Not yet implemented")
    }

}

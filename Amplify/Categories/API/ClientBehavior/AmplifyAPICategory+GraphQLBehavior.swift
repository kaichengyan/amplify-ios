//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension AmplifyAPICategory: APICategoryGraphQLBehavior {

    // MARK: - Request-based GraphQL operations

    public func query<R: Decodable>(request: GraphQLRequest<R>,
                                    listener: GraphQLOperation<R>.ResultListener?) -> GraphQLOperation<R> {
        plugin.query(request: request, listener: listener)
    }

    public func mutate<R: Decodable>(request: GraphQLRequest<R>,
                                     listener: GraphQLOperation<R>.ResultListener?) -> GraphQLOperation<R> {
        plugin.mutate(request: request, listener: listener)
    }

    public func subscribe<R>(request: GraphQLRequest<R>,
                             valueListener: GraphQLSubscriptionOperation<R>.InProcessListener?,
                             completionListener: GraphQLSubscriptionOperation<R>.ResultListener?)
        -> GraphQLSubscriptionOperation<R> {
            plugin.subscribe(request: request, valueListener: valueListener, completionListener: completionListener)
    }
}

/// No-listener versions of the public APIs, to clean the call sites using Combine publishers to get results
@available(iOS 13.0, *)
extension APICategoryGraphQLBehavior {
    public func query<R: Decodable>(request: GraphQLRequest<R>) -> GraphQLOperation<R> {
        query(request: request, listener: nil)
    }

    public func mutate<R: Decodable>(request: GraphQLRequest<R>) -> GraphQLOperation<R> {
        mutate(request: request, listener: nil)
    }

    public func subscribe<R>(request: GraphQLRequest<R>,
                             valueListener: GraphQLSubscriptionOperation<R>.InProcessListener?)
        -> GraphQLSubscriptionOperation<R> {
            subscribe(request: request, valueListener: valueListener, completionListener: nil)
    }
}

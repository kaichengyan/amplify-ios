//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import Foundation

@available(iOS 13.0, *)
public extension AmplifyInProcessOperation where Success == Void {
    var subscriptionPublisher: AnyPublisher<InProcess, Failure> {
        // Suppress Void results from the result publisher, but continue to emit completions
        let transformedResultPublisher = resultPublisher
            .flatMap { _ in Empty<InProcess, Failure>(completeImmediately: true) }

        // Coerce the in process publisher's failure type from Never to Failure
        let transformedInProcessPublisher = inProcessPublisher
            .setFailureType(to: Failure.self)

        // Now that the publisher signatures match, we can merge them
        return transformedResultPublisher
            .merge(with: transformedInProcessPublisher)
            .eraseToAnyPublisher()
    }
}

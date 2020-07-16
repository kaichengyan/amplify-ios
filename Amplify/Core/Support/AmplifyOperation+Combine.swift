//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import Foundation

@available(iOS 13.0, *)
public protocol ResultPublisher {
    associatedtype Success
    associatedtype Failure: AmplifyError

    /// A Publisher that emits the result of the operation, or the associated failure. Cancelled operations will
    /// emit a completion without a value as long as the cancellation was received before the operation was resolved.
    var resultPublisher: AnyPublisher<Success, Failure> { get }
}

@available(iOS 13.0, *)
extension AmplifyOperation: ResultPublisher {
    /// A Publisher that emits the result of the operation, or the associated failure. Cancelled operations will
    /// emit a completion without a value as long as the cancellation was received before the operation was resolved.
    public var resultPublisher: AnyPublisher<Success, Failure> {
        // We set this value in the initializer, so it's safe to force-unwrap and force-cast here
        // swiftlint:disable:next force_cast
        let future = resultFuture as! Future<Success, Failure>
        return future
            .catch(interceptCancellation)
            .eraseToAnyPublisher()
    }

    /// Publish the result of the operation
    ///
    /// - Parameter result: the result of the operation
    func publish(result: OperationResult) {
        // We assign this in init, so we know it's safe to force-unwrap here
        // swiftlint:disable:next force_cast
        let promise = resultPromise as! Future<Success, Failure>.Promise
        promise(result)
    }

    /// Utility method to help Swift type-cast the handling logic for cancellation errors vs. re-thrown errors. The
    /// `try*` operator flavors throw generic `Error` types, which
    /// - Parameter error: The error being intercepted
    /// - Returns: A publisher that either completes successfully (if the underlying error of `error` is a cancellation)
    ///     of re-emits the existing error
    private func interceptCancellation(error: Failure) -> AnyPublisher<Success, Failure> {
        if error.underlyingError is OperationCancelledError {
            return Empty<Success, Failure>(completeImmediately: true).eraseToAnyPublisher()
        } else {
            return Fail<Success, Failure>(error: error).eraseToAnyPublisher()
        }
    }

}

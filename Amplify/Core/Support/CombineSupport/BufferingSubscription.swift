//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import Foundation

/// A Subscription that buffers values until the receiver demands them. Useful for
/// subscribing to Subjects that produce values irrespective of whether there is a
/// downstream subscriber (e.g., a PassthroughSubject used by an imperative process
/// to deliver a stream of events. A BufferingSubscription can be used to request
/// unlimited demand from the upstream publisher, and buffer the values until the
/// downstream subscriber demands them.
@available(iOS 13.0, *)
final class BufferingSubscription<
    Output,
    Failure: Error
>: Subscription, CustomCombineIdentifierConvertible {

    let combineIdentifier: CombineIdentifier

    private var buffer: Buffer
    private var demand: Subscribers.Demand
    private let downstream: AnySubscriber<Output, Failure>
    private let onCompletion: () -> Void

    /// Subscription has been cancelled with `cancel()`
    private var isCancelled: Bool

    /// Subscription has received a completion, even though that completion may be
    /// buffered and not yet delivered to the downstream subscriber
    private var isComplete: Bool

    /// Create a `BufferingSubscription` for the downstream subscriber, with initially
    /// buffered values and optional completion. Use `onCompletion` to signal the
    /// subcription owner to clean up resources allocated to this subscription.
    ///
    /// - Parameters:
    ///   - bufferedValues: the initial buffer of values to deliver to the downstream
    ///     subscriber
    ///   - completion: the initial completion to deliver to the downstream subscriber
    ///   - downstream: the downstream subscriber
    ///   - onCompletion: the closure to invoke when the subscription completes
    init(
        bufferedValues: [Output],
        completion: Subscribers.Completion<Failure>?,
        downstream: AnySubscriber<Output, Failure>,
        onCompletion: @escaping () -> Void
    ) {
        self.combineIdentifier = CombineIdentifier()
        self.demand = .none
        self.isCancelled = false

        self.buffer = Buffer(values: bufferedValues, completion: completion)

        self.isComplete = completion != nil
        self.downstream = downstream
        self.onCompletion = onCompletion
    }

    /// Request `demand` values from the subscription. If there are any buffered
    /// values, deliver them up to the total unsatisfied demand.
    func request(_ demand: Subscribers.Demand) {
        self.demand += demand
        processBuffer()
    }

    /// Finish the subscription and invoke `onCompletion`. The downstream subscriber
    /// will not be notified of the completion, nor of any undelivered buffered values.
    func cancel() {
        guard !isCancelled else {
            return
        }
        isCancelled = true
        isComplete = true
        onCompletion()
    }

    /// Receive a value on the subscription. Buffers the value until the downstream
    /// subscriber demands it.
    func receive(_ value: Output) {
        guard !isCancelled, !isComplete else {
            return
        }

        buffer.append(.value(value))
        processBuffer()
    }

    /// Receive a completion on the subscription. If there are buffered values, buffers
    /// the completion until the queue is drained. Regardless of whether there are
    /// buffered values, the subscription will not accept any new values after
    /// receiving a completion.
    func receive(completion: Subscribers.Completion<Failure>) {
        guard !isCancelled, !isComplete else {
            return
        }
        isComplete = true
        buffer.append(.completion(completion))
        processBuffer()
    }

    /// Deliver buffered values according to unsatisfied demand and cancellation status
    func processBuffer() {
        while !isCancelled, let nextValue = buffer.nextValue(for: demand) {
            switch nextValue {
            case .value(let value):
                demand -= 1
                demand += downstream.receive(value)
            case .completion(let completion):
                downstream.receive(completion: completion)
                onCompletion()
            }
        }
    }
}

@available(iOS 13.0, *)
extension BufferingSubscription {

    /// A buffer of values with demand- and completion-aware accessors
    struct Buffer {
        private var buffer: [Value]

        // swiftlint:disable:next nesting
        enum Value {
            case value(Output)
            case completion(Subscribers.Completion<Failure>)
        }

        /// Create a `Buffer` with the initial values and optional completion
        init(values: [Output], completion: Subscribers.Completion<Failure>?) {
            self.buffer = values.map(Value.value)
            if let completion = completion {
                buffer.append(.completion(completion))
            }
        }

        mutating func append(_ value: Value) {
            buffer.append(value)
        }

        /// Return the next BufferValue to process
        ///
        /// Returns the next BufferValue to process by inspecting the buffer and the
        /// unsatisfied demand, according to the following rules:
        /// - If the first value is a completion, return it regardless of whether there is
        /// unsatisfied demand
        /// - If there is unsatisfied demand and the buffer has any value, return the first
        /// value
        /// - Otherwise, return nil
        mutating func nextValue(for demand: Subscribers.Demand) -> Value? {
            guard !buffer.isEmpty else {
                return nil
            }

            if case .completion = buffer.first {
                return buffer.removeFirst()
            }

            guard demand > 0 else {
                return nil
            }

            return buffer.removeFirst()
        }
    }

}

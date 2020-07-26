//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import Foundation

/// A Subject that buffers events from its upstream subscriber until it receives a subscription.
/// Upon receiving the first subscription, replays any buffered events to that subscription alone,
/// then simply passes through events as they are received. If the first subscriber subsequently
/// cancels its subscription, the `ReplayOnceSubject` will not resume buffering; instead, events
/// will be dropped just like with a `PassthroughSubject`.
///
/// Inspired by ShareReplay described at
/// https://www.onswiftwings.com/posts/share-replay-operator/
@available(iOS 13.0, *)
public final class ReplayOnceSubject<Output, Failure: Error>: Subject {
    private var buffer: [Output]? = []
    private var completion: Subscribers.Completion<Failure>?
    private let lock = NSRecursiveLock()
    private var subscriptions = [CombineIdentifier: BufferingSubscription<Output, Failure>]()

    private var isBuffering: Bool {
        buffer != nil
    }

    /// Establishes a subscription for a new subscriber.
    ///
    /// The first subscriber to subscribe to this `ReplaceOnceSubject` will receive any
    /// buffered events, then events as they are sent by the upstream publisher.
    /// Subsequent subscribers will receive upstream events as the publisher produces
    /// them, as normal.
    public func receive<S: Subscriber>(
        subscriber: S
    ) where S.Failure == Failure, S.Input == Output {
        lock.lock()

        defer {
            lock.unlock()
        }

        var subscription: BufferingSubscription<Output, Failure>!
        let onCompletion: () -> Void = {
            self.subscriptions.removeValue(forKey: subscription.combineIdentifier)
        }
        subscription = BufferingSubscription(
            bufferedValues: buffer ?? [],
            completion: completion,
            downstream: AnySubscriber(subscriber),
            onCompletion: onCompletion
        )
        buffer = nil

        subscriptions[subscription.combineIdentifier] = subscription

        let someSubscription = subscription as Subscription
        subscriber.receive(subscription: someSubscription)

        subscription.processBuffer()
    }

    /// Included for conformance to `Subject`, but this method should never be invoked.
    /// Subscriptions are created in `receive(subscriber:)`, and upstream subscriptions
    /// are managed via the `ReplayOnce` publisher.
    public func send(subscription: Subscription) {
        // Do nothing
    }

    /// Sends a value to connected subscribers. If there are no current subscribers of
    /// this subject, buffers the value until the first subscriber is received.
    public func send(_ value: Output) {
        lock.lock()
        defer {
            lock.unlock()
        }

        guard !isBuffering else {
            buffer!.append(value)
            return
        }

        subscriptions.values.forEach { $0.receive(value) }
    }

    /// Send a completion to connected subscribers. If there are no current subscribers
    /// of this subject, buffer the completion until the first subscriber is received.
    /// The first subscriber will receive buffered events and the completion, similar
    /// to the behavior of `Publishers.Record`.
    public func send(completion: Subscribers.Completion<Failure>) {
        lock.lock()
        defer {
            lock.unlock()
        }

        self.completion = completion
        subscriptions.values.forEach { $0.receive(completion: completion) }
    }
}

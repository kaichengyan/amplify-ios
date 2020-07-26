//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import Foundation

@available(iOS 13.0, *)
public extension Publisher {

    /// Buffers values produced by the current publisher until a downstream subscriber
    /// attaches. This is different from `makeConnectable`, which causes the current
    /// publisher to not produce values until `connect` is invoked. By using
    /// `replayOnce`, the source beings producing values immediately, even if no
    /// subscriber is present. Subsequent connections to this publisher will not
    /// receive the initially buffered values, only values produced after they
    /// subscribe.
    ///
    /// Subscribers connecting to a ReplayOnce publisher are ensured to receive all
    /// values produced after they connect, even if they are not demanding values while
    /// the publisher produces them.
    ///
    /// ## Example
    /// In the following code sample:
    ///
    /// ```
    /// let subject = PassthroughSubject<Int, Never>()
    /// let publisher = subject.eraseToAnyPublisher()
    /// subject.send(1)
    /// subject.send(2)
    /// subject.send(3)
    ///
    /// let sink = publisher.sink { print($0) }
    /// subject.send(4)
    /// subject.send(completion: .finished)
    /// ```
    ///
    /// The sink only prints "4". The first three values are dropped because they were
    /// produced before the sink was attached.
    ///
    /// By using the `replayOnce()` operator:
    ///
    /// ```
    /// let subject = PassthroughSubject<Int, Never>()
    /// let publisher = subject.replayOnce().eraseToAnyPublisher()
    /// subject.send(1)
    /// subject.send(2)
    /// subject.send(3)
    ///
    /// let sink = publisher.sink { print($0) }
    /// subject.send(4)
    /// subject.send(completion: .finished)
    /// ```
    ///
    /// The sink now prints 1, 2, 3, 4, since it receives the buffered values when it
    /// connects.
    func replayOnce() -> Publishers.ReplayOnce<Self> {
        Publishers.ReplayOnce(upstream: self)
    }
}

@available(iOS 13.0, *)
public extension Publishers {

    /// A Publisher that immediately connects to its upstream source and buffers values until the
    /// first downstream subscription is received
    class ReplayOnce<Upstream: Publisher>: Publisher {
        // swiftlint:disable:next nesting
        public typealias Output = Upstream.Output

        // swiftlint:disable:next nesting
        public typealias Failure = Upstream.Failure

        public let combineIdentifier = CombineIdentifier()
        private let upstream: Upstream
        private let subject: ReplayOnceSubject<Output, Failure>
        private var subscription: Subscription?

        public init(upstream: Upstream) {
            self.subject = ReplayOnceSubject()
            self.upstream = upstream
            upstream.subscribe(self)
        }

        public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
            subject.receive(subscriber: subscriber)
        }
    }

}

@available(iOS 13.0, *)
extension Publishers.ReplayOnce: Subscriber {
    public typealias Input = Output

    public func receive(_ input: Output) -> Subscribers.Demand {
        subject.send(input)
        return .unlimited
    }

    public func receive(completion: Subscribers.Completion<Upstream.Failure>) {
        subject.send(completion: completion)
    }

    public func receive(subscription: Subscription) {
        self.subscription = subscription
        subscription.request(.unlimited)
    }
}

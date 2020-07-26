//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import XCTest

import Amplify

/// This class covers the entire chain of Operator, Publisher, Subscriber and Subject, so we don't
/// need individual tests for those components
@available(iOS 13.0, *)
class ReplayOnceOperatorTests: XCTestCase {

    let subject = PassthroughSubject<Int, Never>()

    func testReceivesAllValues() {
        let replayPublisher = subject.replayOnce()
        let receivedExpectedValues = expectation(description: "receivedExpectedValues")
        receivedExpectedValues.expectedFulfillmentCount = 3
        let receivedCompletion = expectation(description: "receivedCompletion")

        subject.send(1)
        subject.send(2)

        let sink = replayPublisher
            .sink(
                receiveCompletion: { _ in receivedCompletion.fulfill() },
                receiveValue: { _ in receivedExpectedValues.fulfill() }
        )

        subject.send(3)
        subject.send(completion: .finished)

        waitForExpectations(timeout: 1.0)
        sink.cancel()
    }

    func testReceivesAllValuesAfterCompletion() {
        let replayPublisher = subject.replayOnce()
        let receivedExpectedValues = expectation(description: "receivedExpectedValues")
        receivedExpectedValues.expectedFulfillmentCount = 3
        let receivedCompletion = expectation(description: "receivedCompletion")

        subject.send(1)
        subject.send(2)
        subject.send(3)
        subject.send(completion: .finished)

        let sink = replayPublisher
            .sink(
                receiveCompletion: { _ in receivedCompletion.fulfill() },
                receiveValue: { _ in receivedExpectedValues.fulfill() }
        )

        waitForExpectations(timeout: 1.0)
        sink.cancel()
    }

    func testReceivesAllValuesSentAfterSubscription() {
        let replayPublisher = subject.replayOnce()
        let receivedExpectedValues = expectation(description: "receivedExpectedValues")
        receivedExpectedValues.expectedFulfillmentCount = 3
        let receivedCompletion = expectation(description: "receivedCompletion")

        let sink = replayPublisher
            .sink(
                receiveCompletion: { _ in receivedCompletion.fulfill() },
                receiveValue: { _ in receivedExpectedValues.fulfill() }
        )

        subject.send(1)
        subject.send(2)
        subject.send(3)
        subject.send(completion: .finished)

        waitForExpectations(timeout: 1.0)
        sink.cancel()
    }

    func testOnlyReplaysForFirstSubscriber() {
        let replayPublisher = subject.replayOnce()
        let sink1ReceivedExpectedValues = expectation(description: "sink1ReceivedExpectedValues")
        sink1ReceivedExpectedValues.expectedFulfillmentCount = 3
        let sink1ReceivedCompletion = expectation(description: "sink1ReceivedCompletion")

        let sink2ReceivedExpectedValues = expectation(description: "sink2ReceivedExpectedValues")
        sink2ReceivedExpectedValues.expectedFulfillmentCount = 1
        let sink2ReceivedCompletion = expectation(description: "sink2ReceivedCompletion")

        subject.send(1)
        subject.send(2)

        let sink1 = replayPublisher
            .sink(
                receiveCompletion: { _ in sink1ReceivedCompletion.fulfill() },
                receiveValue: { _ in sink1ReceivedExpectedValues.fulfill() }
        )

        let sink2 = replayPublisher
            .sink(
                receiveCompletion: { _ in sink2ReceivedCompletion.fulfill() },
                receiveValue: { _ in sink2ReceivedExpectedValues.fulfill() }
        )

        subject.send(3)
        subject.send(completion: .finished)

        waitForExpectations(timeout: 1.0)
        sink1.cancel()
        sink2.cancel()
    }

    func testOnlyDeliversOnDemand() {
        let replayPublisher = subject.replayOnce()

        let subscriberReceivedExpectedValues = expectation(description: "subscriberReceivedExpectedValues")
        subscriberReceivedExpectedValues.expectedFulfillmentCount = 2
        let subscriberReceivedCompletion = expectation(description: "subscriberReceivedCompletion")
        subscriberReceivedCompletion.isInverted = true

        let subscriber = TestSubscriber<Int, Never>(
            receivedValue: subscriberReceivedExpectedValues,
            receivedCompletion: subscriberReceivedCompletion
        )

        subject.send(1)
        subject.send(2)
        subject.send(3)

        replayPublisher.subscribe(subscriber)
        subscriber.next()
        subscriber.next()

        subject.send(4)
        subject.send(completion: .finished)
        waitForExpectations(timeout: 0.05)
    }

    func testDoesNotDeliverAfterComplete() {
        let replayPublisher = subject.replayOnce()
        let receivedExpectedValues = expectation(description: "receivedExpectedValues")
        receivedExpectedValues.expectedFulfillmentCount = 2
        let receivedCompletion = expectation(description: "receivedCompletion")

        subject.send(1)
        subject.send(2)
        subject.send(completion: .finished)
        subject.send(3)

        let sink = replayPublisher
            .sink(
                receiveCompletion: { _ in receivedCompletion.fulfill() },
                receiveValue: { _ in receivedExpectedValues.fulfill() }
        )

        waitForExpectations(timeout: 1.0)
        sink.cancel()
    }

    func testDoesNotDeliverAfterSinkCancel() {
        let replayPublisher = subject.replayOnce()
        let receivedExpectedValues = expectation(description: "receivedExpectedValues")
        receivedExpectedValues.expectedFulfillmentCount = 1
        let receivedCompletion = expectation(description: "receivedCompletion")
        receivedCompletion.isInverted = true

        let sink = replayPublisher
            .sink(
                receiveCompletion: { _ in receivedCompletion.fulfill() },
                receiveValue: { _ in receivedExpectedValues.fulfill() }
        )

        subject.send(1)
        sink.cancel()
        subject.send(2)
        subject.send(3)
        subject.send(completion: .finished)

        waitForExpectations(timeout: 1.0)
    }

    func testDoesNotDeliverAfterSubscriberCancel() {
        let replayPublisher = subject.replayOnce()

        let subscriberReceivedExpectedValues = expectation(description: "subscriberReceivedExpectedValues")
        subscriberReceivedExpectedValues.expectedFulfillmentCount = 1
        let subscriberReceivedCompletion = expectation(description: "subscriberReceivedCompletion")
        subscriberReceivedCompletion.isInverted = true

        let subscriber = TestSubscriber<Int, Never>(
            receivedValue: subscriberReceivedExpectedValues,
            receivedCompletion: subscriberReceivedCompletion
        )

        subject.send(1)
        replayPublisher.subscribe(subscriber)
        subscriber.next()
        subscriber.next()
        subscriber.cancel()
        subject.send(2)
        subject.send(3)
        subject.send(completion: .finished)
        waitForExpectations(timeout: 0.05)
    }

}

@available(iOS 13.0, *)
extension ReplayOnceOperatorTests {

    class TestSubscriber<Input, Failure: Error>: Subscriber {
        private var subscription: Subscription?
        let receivedValue: XCTestExpectation
        let receivedCompletion: XCTestExpectation

        init(receivedValue: XCTestExpectation, receivedCompletion: XCTestExpectation) {
            self.receivedValue = receivedValue
            self.receivedCompletion = receivedCompletion
        }

        func next() {
            subscription?.request(.max(1))
        }

        func cancel() {
            subscription?.cancel()
        }

        func receive(subscription: Subscription) {
            self.subscription = subscription
            subscription.request(.none)
        }

        func receive(_ input: Input) -> Subscribers.Demand {
            receivedValue.fulfill()
            return .none
        }

        func receive(completion: Subscribers.Completion<Failure>) {
            receivedCompletion.fulfill()
        }
    }

}

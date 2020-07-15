//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import Foundation

/// An AmplifyOperation that emits InProcess values intermittently during the operation.
///
/// Unlike a regular `AmplifyOperation`, which emits a single Result at the completion of the operation's work, an
/// `AmplifyInProcessReportingOperation` may emit intermediate values while its work is ongoing. These values could be
/// incidental to the operation (such as a `Storage.downloadFile` operation reporting Progress values periodically as
/// the download proceeds), or they could be the primary delivery mechanism for an operation (such as a
/// `GraphQLSubscriptionOperation`'s emitting new subscription values).
open class AmplifyInProcessReportingOperation<
    Request: AmplifyOperationRequest,
    InProcess,
    Success,
    Failure: AmplifyError
>: AmplifyOperation<Request, Success, Failure> {
    var inProcessListenerUnsubscribeToken: UnsubscribeToken?

    /// Local storage for the result publisher associated with this operation. In iOS 13 and higher, this is initialized
    /// to be a `PassthroughSubject<InProcess, Failure>`. In versions of iOS prior to 13, this is initialized to
    /// `false`.
    private var _inProcessSubject: Any

    @available(iOS 13.0, *)
    public var inProcessPublisher: AnyPublisher<InProcess, Failure> {
        // We set this value in the initializer of, so it's safe to force-unwrap here
        // swiftlint:disable:next force_cast
        let subject = _inProcessSubject as! PassthroughSubject<InProcess, Failure>
        return subject.eraseToAnyPublisher()
    }

    public init(categoryType: CategoryType,
                eventName: HubPayloadEventName,
                request: Request,
                inProcessListener: InProcessListener? = nil,
                resultListener: ResultListener? = nil) {

        if #available(iOS 13.0, *) {
            _inProcessSubject = PassthroughSubject<InProcess, Failure>()
        } else {
            self._inProcessSubject = false
        }

        super.init(categoryType: categoryType, eventName: eventName, request: request, resultListener: resultListener)

        if #available(iOS 13.0, *) {
            // We assign this immediately above, so we know it's safe to force-unwrap here
            // swiftlint:disable:next force_cast
            let subject = _inProcessSubject as! PassthroughSubject<InProcess, Failure>
            subscribe(inProcessSubject: subject)
        }

        // If the inProcessListener is present, we need to register a hub event listener for it, and ensure we
        // automatically unsubscribe when we receive a completion event for the operation
        if let inProcessListener = inProcessListener {
            self.inProcessListenerUnsubscribeToken = subscribe(inProcessListener: inProcessListener)
        }
    }

    /// Registers an in-process listener for this operation. If the operation completes, this listener will
    /// automatically be removed.
    ///
    /// - Parameter inProcessListener: The listener for in-process events
    /// - Returns: an UnsubscribeToken that can be used to remove the listener from Hub
    func subscribe(inProcessListener: @escaping InProcessListener) -> UnsubscribeToken {
        let channel = HubChannel(from: categoryType)
        let filterById = HubFilters.forOperation(self)

        var inProcessListenerToken: UnsubscribeToken!
        let inProcessHubListener: HubListener = { payload in
            if let inProcessData = payload.data as? InProcess {
                inProcessListener(inProcessData)
                return
            }
            // Remove listener if we see a result come through
            if payload.data is OperationResult {
                Amplify.Hub.removeListener(inProcessListenerToken)
            }
        }

        inProcessListenerToken = Amplify.Hub.listen(to: channel,
                                                    isIncluded: filterById,
                                                    listener: inProcessHubListener)

        return inProcessListenerToken
    }

}

public extension AmplifyInProcessReportingOperation {
    /// Convenience typealias for the `inProcessListener` callback submitted during Operation creation
    typealias InProcessListener = (InProcess) -> Void

    /// Dispatches an event to the hub. Internally, creates an `AmplifyOperationContext` object from the
    /// operation's `id`, and `request`
    /// - Parameter result: The OperationResult to dispatch to the hub as part of the HubPayload
    func dispatchInProcess(data: InProcess) {
        let channel = HubChannel(from: categoryType)
        let context = AmplifyOperationContext(operationId: id, request: request)
        let payload = HubPayload(eventName: eventName, context: context, data: data)
        Amplify.Hub.dispatch(to: channel, payload: payload)
    }

    /// Removes the listener that was registered during operation instantiation
    func removeInProcessResultListener() {
        if let inProcessListenerUnsubscribeToken = inProcessListenerUnsubscribeToken {
            Amplify.Hub.removeListener(inProcessListenerUnsubscribeToken)
        }
    }

}

@available(iOS 13.0, *)
private extension AmplifyInProcessReportingOperation {
    /// Subscribe a subject to this operation's Hub events. Once a result (as opposed to an in-process value) is
    /// received, unsubscribes from the Hub listener and sends a completion to the subject.
    ///
    /// - Parameter subject: A Subject to receive a Hub result for this operation
    func subscribe<S>(inProcessSubject: S) where S: Subject, S.Output == InProcess, S.Failure == Failure {
        let channel = HubChannel(from: categoryType)
        let filterById = HubFilters.forOperation(self)

        var inProcessListenerToken: UnsubscribeToken!
        let inProcessHubListener: HubListener = { payload in
            if let inProcessData = payload.data as? InProcess {
                inProcessSubject.send(inProcessData)
                return
            }

            guard let result = payload.data as? OperationResult else {
                return
            }

            switch result {
            case .success:
                inProcessSubject.send(completion: .finished)
            case .failure(let error):
                inProcessSubject.send(completion: .failure(error))
            }

            Amplify.Hub.removeListener(inProcessListenerToken)
        }

        inProcessListenerToken = Amplify.Hub.listen(to: channel,
                                                    isIncluded: filterById,
                                                    listener: inProcessHubListener)
    }
}

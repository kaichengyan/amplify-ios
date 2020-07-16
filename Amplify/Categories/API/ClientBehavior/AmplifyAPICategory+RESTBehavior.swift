//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AmplifyAPICategory: APICategoryRESTBehavior {
    public func get(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        plugin.get(request: request, listener: listener)
    }

    public func put(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        plugin.put(request: request, listener: listener)
    }

    public func post(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        plugin.post(request: request, listener: listener)
    }

    public func delete(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        plugin.delete(request: request, listener: listener)
    }

    public func head(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        plugin.head(request: request, listener: listener)
    }

    public func patch(request: RESTRequest, listener: RESTOperation.ResultListener?) -> RESTOperation {
        plugin.patch(request: request, listener: listener)
    }
}

/// No-listener versions of the public APIs, to clean the call sites using Combine publishers to get results
@available(iOS 13.0, *)
extension APICategoryRESTBehavior {
    public func get(request: RESTRequest) -> RESTOperation {
        get(request: request, listener: nil)
    }

    public func put(request: RESTRequest) -> RESTOperation {
        put(request: request, listener: nil)
    }

    public func post(request: RESTRequest) -> RESTOperation {
        post(request: request, listener: nil)
    }

    public func delete(request: RESTRequest) -> RESTOperation {
        delete(request: request, listener: nil)
    }

    public func head(request: RESTRequest) -> RESTOperation {
        head(request: request, listener: nil)
    }

    public func patch(request: RESTRequest) -> RESTOperation {
        patch(request: request, listener: nil)
    }
}

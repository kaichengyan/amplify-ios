//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import Foundation

@available(iOS 13.0, *)
extension StorageCategoryBehavior {

    public func getURL(
        key: String,
        options: StorageGetURLRequest.Options? = nil
    ) -> StorageGetURLOperation {
        getURL(key: key, options: nil, resultListener: nil)
    }

    public func downloadData(
        key: String,
        options: StorageDownloadDataRequest.Options? = nil
    ) -> StorageDownloadDataOperation {
        downloadData(key: key,
                     options: options,
                     progressListener: nil,
                     resultListener: nil)
    }

    public func downloadFile(
        key: String,
        local: URL,
        options: StorageDownloadFileRequest.Options? = nil
    ) -> StorageDownloadFileOperation {
        downloadFile(key: key,
                     local: local,
                     options: options,
                     progressListener: nil,
                     resultListener: nil)
    }

    public func uploadData(
        key: String,
        data: Data,
        options: StorageUploadDataRequest.Options? = nil
    ) -> StorageUploadDataOperation {
        uploadData(key: key,
                   data: data,
                   options: options,
                   progressListener: nil,
                   resultListener: nil)
    }

    public func uploadFile(
        key: String,
        local: URL,
        options: StorageUploadFileRequest.Options? = nil
    ) -> StorageUploadFileOperation {
        uploadFile(key: key,
                   local: local,
                   options: options,
                   progressListener: nil,
                   resultListener: nil)
    }

    public func remove(
        key: String,
        options: StorageRemoveRequest.Options? = nil
    ) -> StorageRemoveOperation {
        remove(key: key, options: options, resultListener: nil)
    }

    public func list(options: StorageListRequest.Options? = nil) -> StorageListOperation {
        list(options: options, resultListener: nil)
    }
}

/**
 * Copyright IBM Corporation 2018
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Foundation

/** ListObjectsResult. */
public struct ListObjectsResult: Decodable {

    /// Bucket Name
    public var name: String?

    /// Prefix
    public var prefix: String?

    /// KeyCount
    public var keyCount: Int?

    /// Max KeyCount
    public var maxKeys: Int?

    /// Delimiter
    public var delimiter: String?

    /// isTruncated
    public var isTruncated: Bool?

    public var contents: [ListObjectsResultContents]?

    // Map each property name to the key that shall be used for encoding/decoding.
    private enum CodingKeys: String, CodingKey {
        case name = "Name"
        case prefix = "Prefix"
        case keyCount = "KeyCount"
        case maxKeys = "MaxKeys"
        case delimiter = "Delimiter"
        case isTruncated = "IsTruncated"
        case contents = "Contents"
    }
}

/** ListObjectsResultContents. */
public struct ListObjectsResultContents: Decodable {

    /// Object Name
    public var key: String?

    /// Last Modified
    public var lastModified: String?

    /// ETag
    public var eTag: String?

    /// Size
    public var size: Int?

    /// Storage Class
    public var storageClass: String?

    // Map each property name to the key that shall be used for encoding/decoding.
    private enum CodingKeys: String, CodingKey {
        case key = "Key"
        case lastModified = "LastModified"
        case eTag = "ETag"
        case size = "Size"
        case storageClass = "StorageClass"
    }
}

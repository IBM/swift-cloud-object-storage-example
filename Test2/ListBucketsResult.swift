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

/** ListBucketsResult. */
public struct ListBucketsResult: Decodable {
    public var owner: ListBucketsResultOwner?

    public var buckets: [ListBucketsResultBuckets]?

    // Map each property name to the key that shall be used for encoding/decoding.
    private enum CodingKeys: String, CodingKey {
        case owner = "Owner"
        case buckets = "Buckets"
    }
}

public struct ListBucketsResultBuckets: Decodable {
    /// Buckets
    public var bucket: [ListBucketsResultBucket]?

    // Map each property name to the key that shall be used for encoding/decoding.
    private enum CodingKeys: String, CodingKey {
        case bucket = "Bucket"
    }
}

/** ListBucketsResultBucket. */
public struct ListBucketsResultBucket: Decodable {

    /// Bucket Name.
    public var name: String?

    /// Creation Date.
    public var creationDate: String?

    // Map each property name to the key that shall be used for encoding/decoding.
    private enum CodingKeys: String, CodingKey {
        case name = "Name"
        case creationDate = "CreationDate"
    }
}

/** ListBucketsResultOwner. */
public struct ListBucketsResultOwner: Decodable {
    /// Account ID.
    public var ID: String?

    /// Display Name.
    public var displayName: String?

    // Map each property name to the key that shall be used for encoding/decoding.
    private enum CodingKeys: String, CodingKey {
        case ID
        case displayName = "DisplayName"
    }
}

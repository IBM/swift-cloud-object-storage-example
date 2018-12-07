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

/** ErrorResult. */
public struct ErrorResult: Decodable {

    /// Error Code
    public var code: String?

    /// Error Message
    public var message: String?

    /// Resource
    public var resource: String?

    /// RequestId
    public var requestId: String?

    /// HTTP Status Code
    public var httpStatusCode: Int?

    // Map each property name to the key that shall be used for encoding/decoding.
    private enum CodingKeys: String, CodingKey {
        case code = "Code"
        case message = "Message"
        case resource = "Resource"
        case requestId = "RequestId"
        case httpStatusCode = "httpStatusCode"
    }
}

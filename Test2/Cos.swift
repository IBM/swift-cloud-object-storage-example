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
import RestKit
import XMLParsing

/// Cloud Object Storage SDK
public class COS {
    /// The base URL to use when contacting the service.
    public var serviceURL: String

    private let session = URLSession(configuration: URLSessionConfiguration.default)
    private var authMethod: AuthenticationMethod
    private let ibmServiceInstanceID: String

    private let domain = "com.ibm.COS"
    private let listObjectsApiVersion = 2   // version of listObjects API endpoint

    /**
     Create a `COS` object.

     - parameter apiKey: An API key for IAM that can be used to obtain access tokens for the service.
     - parameter ibmServiceInstanceID: References the service instance where the bucket will be created and to which data usage will be billed.
     - parameter region: The region to use for the service
     - parameter iamUrl: The URL for the IAM service.
     */
    public init(apiKey: String, ibmServiceInstanceID: String, region: CosRegion = CosRegion.usCross, iamUrl: String? = nil) {
        self.authMethod = IAMAuthentication(apiKey: apiKey, url: iamUrl)
        self.ibmServiceInstanceID = ibmServiceInstanceID
        self.serviceURL = region.url()
    }

    /**
     Create a `COS` object.

     - parameter accessToken: An access token for the service.
     - parameter ibmServiceInstanceID: References the service instance where the bucket will be created and to which data usage will be billed.
     */
    public init(accessToken: String, ibmServiceInstanceID: String, region: CosRegion = CosRegion.usCross) {
        self.authMethod = IAMAccessToken(accessToken: accessToken)
        self.ibmServiceInstanceID = ibmServiceInstanceID
        self.serviceURL = region.url()
    }

    public func accessToken(_ newToken: String) {
        if self.authMethod is IAMAccessToken {
            self.authMethod = IAMAccessToken(accessToken: newToken)
        }
    }

    /**
     If the response or data represents an error returned by the COS API service,
     then return NSError with information about the error that occured. Otherwise, return nil.

     - parameter response: the URL response returned from the service.
     - parameter data: Raw data returned from the service that may represent an error.
     */
    private func errorResponseDecoder(data: Data, response: HTTPURLResponse) -> Error {

        let code = response.statusCode

        do {
            let result = try XMLDecoder().decode(ErrorResult.self, from: data)

            var userInfo: [String: Any] = [:]

            guard
                let errorCode = result.code,
                let message = result.message
            else {
                return NSError(domain: domain, code: code, userInfo: nil)
            }

            userInfo[NSLocalizedDescriptionKey] = "\(errorCode): \(message)"

            return NSError(domain: domain, code: code, userInfo: userInfo)
        } catch {
            return NSError(domain: domain, code: code, userInfo: nil)
        }
    }

    /**
     Create a new bucket.

     A PUT issued to the endpoint root will create a bucket when a string is provided. Bucket names must be unique, and
     accounts are limited to 100 buckets each. Bucket names must be DNS-compliant; names between 3 and 63 characters
     long must be made of lowercase letters, numbers, and dashes. Bucket names must begin and end with a lowercase
     letter or number. Bucket names resembling IP addresses are not allowed. This operation does not make use of
     operation specific query parameters.

     - parameter bucketName: Name of the bucket.
     - parameter ibmServiceInstanceID: References the service instance where the bucket will be created and to which data usage will be billed.
     - parameter failure: A function executed if an error occurs.
     - parameter success: A function executed with the successful result.
     */
    public func createBucket(
        bucketName: String,
        failure: ((Error) -> Void)? = nil,
        success: @escaping () -> Void
    ) {
        // construct header parameters
        var headers = [String: String]()
        headers["Content-Type"] = "text/plain"
        headers["ibm-service-instance-id"] = ibmServiceInstanceID

        // construct REST request
        let path = "/\(bucketName)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            failure?(RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "PUT",
            url: serviceURL + encodedPath,
            headerParameters: headers
        )

        // execute REST request
        request.responseVoid {
            (response: RestResponse) in
            switch response.result {
            case .success: success()
            case let .failure(error): failure?(error)
            }
        }
    }

    /**
     Upload an object.

     - parameter bucketName: Name of the bucket.
     - parameter objectName: Name of the object.
     - parameter failure: A function executed if an error occurs.
     - parameter success: A function executed with the successful result.
     */
    public func createObject(
        bucketName: String,
        objectName: String,
        body: Data,
        failure: ((Error) -> Void)? = nil,
        success: @escaping () -> Void
    ) {
        // construct header parameters
        var headers = [String: String]()
        headers["Accept"] = "application/xml"

        // construct REST request
        let path = "/\(bucketName)/\(objectName)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            failure?(RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "PUT",
            url: serviceURL + encodedPath,
            headerParameters: headers,
            messageBody: body
        )

        // execute REST request
        request.responseVoid {
            (response: RestResponse) in
            switch response.result {
            case .success: success()
            case let .failure(error): failure?(error)
            }
        }
    }

    /**
     Delete a bucket.

     A DELETE issued to an empty bucket deletes the bucket. After deleting a bucket the name will be held in reserve by
     the system for 10 minutes, after which it will be released for re-use. Only empty buckets can be deleted.

     - parameter bucketName: Name of the bucket.
     - parameter failure: A function executed if an error occurs.
     - parameter success: A function executed with the successful result.
     */
    public func deleteBucket(
        bucketName: String,
        failure: ((Error) -> Void)? = nil,
        success: @escaping () -> Void
    ) {
        // construct header parameters
        let headers = [String: String]()

        // construct REST request
        let path = "/\(bucketName)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            failure?(RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "DELETE",
            url: serviceURL + encodedPath,
            headerParameters: headers
        )

        // execute REST request
        request.responseVoid {
            (response: RestResponse) in
            switch response.result {
            case .success: success()
            case let .failure(error): failure?(error)
            }
        }
    }

    /**
     Delete an object.

     A DELETE given a path to an object deletes an object.

     - parameter bucketName: Name of the bucket.
     - parameter objectName: Name of the object.
     - parameter failure: A function executed if an error occurs.
     - parameter success: A function executed with the successful result.
     */
    public func deleteObject(
        bucketName: String,
        objectName: String,
        failure: ((Error) -> Void)? = nil,
        success: @escaping () -> Void
    ) {
        // construct header parameters
        let headers = [String: String]()

        // construct REST request
        let path = "/\(bucketName)/\(objectName)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            failure?(RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "DELETE",
            url: serviceURL + encodedPath,
            headerParameters: headers
        )

        // execute REST request
        request.responseVoid {
            (response: RestResponse) in
            switch response.result {
            case .success: success()
            case let .failure(error): failure?(error)
            }
        }
    }

    /**
     Download an object.

     A GET given a path to an object downloads the object.

     - parameter bucketName: Name of the bucket.
     - parameter objectName: Name of the object.
     - parameter range: Returns the bytes of an object within the specified range.
     - parameter failure: A function executed if an error occurs.
     - parameter success: A function executed with the successful result.
     */
    public func getObject(
        bucketName: String,
        objectName: String,
        range: String? = nil,
        failure: ((Error) -> Void)? = nil,
        success: @escaping (Data) -> Void
    ) {
        // construct header parameters
        var headers = [String: String]()
        headers["Accept"] = "text/plain"
        if let range = range {
            headers["range"] = range
        }

        // construct REST request
        let path = "/\(bucketName)/\(objectName)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            failure?(RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "GET",
            url: serviceURL + encodedPath,
            headerParameters: headers
        )

        // execute REST request
        request.responseData {
            (response: RestResponse) in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                success(data)
            case let .failure(error): failure?(error)
            }
        }
    }

    /**
     List buckets belonging to an account.

     A GET issued to the endpoint root returns a list of buckets associated with the specified service instance. This
     operation does not make use of operation specific query parameters or payload elements.

     - parameter failure: A function executed if an error occurs.
     - parameter success: A function executed with the successful result.
     */
    public func listBuckets(
        failure: ((Error) -> Void)? = nil,
        success: @escaping (ListBucketsResult) -> Void
    ) {
        // construct header parameters
        var headers = [String: String]()
        headers["Accept"] = "application/xml"
        headers["ibm-service-instance-id"] = ibmServiceInstanceID

        // construct REST request
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "GET",
            url: serviceURL + "/",
            headerParameters: headers
        )

        // execute REST request
        request.responseString {
            (response: RestResponse) in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let result = try XMLDecoder().decode(ListBucketsResult.self, from: data)
                    success(result)
                } catch {
                    failure?(error)
                }
            case let .failure(error): failure?(error)
            }
        }
    }

    /**
     List objects in a given bucket.

     A GET request addressed to a bucket returns a list of objects, limited to 1,000 at a time and returned in
     non-lexographical order. The StorageClass value that is returned in the response is a default value as storage
     class operations are not implemented in COS. This operation does not make use of operation specific headers or
     payload elements.

     - parameter bucketName: Name of the bucket.
     - parameter namePrefix: Constrains response to object names beginning with prefix.
     - parameter delimiter: Groups objects between the prefix and the delimiter.
     - parameter encodingType: If unicode characters that are not supported by XML are used in an object name, this parameter can be set to url to
     properly encode the response.
     - parameter maxKeys: Restricts the number of objects to display in the response. Default and maximum is 1,000.
     - parameter fetchOwner: Version 2 of the API does not include the Owner information by default. Set this parameter to true if Owner
     information is desired in the response.
     - parameter continuationToken: Specifies the next set of objects to be returned when your response is truncated (IsTruncated element returns
     true). Your initial response will include the NextContinuationToken element. Use this token in the next request as
     the value for continuation-token.
     - parameter startAfter: Returns key names after a specific key object. This parameter is only valid in your initial request. If a
     continuation-token parameter is included in your request, this parameter is ignored.
     - parameter failure: A function executed if an error occurs.
     - parameter success: A function executed with the successful result.
     */
    public func listObjects(
        bucketName: String,
        namePrefix: String? = nil,
        delimiter: String? = nil,
        encodingType: String? = nil,
        maxKeys: Int? = nil,
        fetchOwner: String? = nil,
        continuationToken: String? = nil,
        startAfter: String? = nil,
        failure: ((Error) -> Void)? = nil,
        success: @escaping (ListObjectsResult) -> Void
    ) {
        // construct header parameters
        var headers = [String: String]()
        headers["Accept"] = "application/xml"

        // construct query parameters
        var queryParameters = [URLQueryItem]()
        queryParameters.append(URLQueryItem(name: "list-type", value: "\(listObjectsApiVersion)"))
        if let namePrefix = namePrefix {
            let queryParameter = URLQueryItem(name: "prefix", value: namePrefix)
            queryParameters.append(queryParameter)
        }
        if let delimiter = delimiter {
            let queryParameter = URLQueryItem(name: "delimiter", value: delimiter)
            queryParameters.append(queryParameter)
        }
        if let encodingType = encodingType {
            let queryParameter = URLQueryItem(name: "encoding-type", value: encodingType)
            queryParameters.append(queryParameter)
        }
        if let maxKeys = maxKeys {
            let queryParameter = URLQueryItem(name: "max-keys", value: "\(maxKeys)")
            queryParameters.append(queryParameter)
        }
        if let fetchOwner = fetchOwner {
            let queryParameter = URLQueryItem(name: "fetch-owner", value: fetchOwner)
            queryParameters.append(queryParameter)
        }
        if let continuationToken = continuationToken {
            let queryParameter = URLQueryItem(name: "continuation-token", value: continuationToken)
            queryParameters.append(queryParameter)
        }
        if let startAfter = startAfter {
            let queryParameter = URLQueryItem(name: "start-after", value: startAfter)
            queryParameters.append(queryParameter)
        }

        // construct REST request
        let path = "/\(bucketName)"
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            failure?(RestError.encodingError)
            return
        }
        let request = RestRequest(
            session: session,
            authMethod: authMethod,
            errorResponseDecoder: errorResponseDecoder,
            method: "GET",
            url: serviceURL + encodedPath,
            headerParameters: headers,
            queryItems: queryParameters
        )

        // execute REST request
        request.responseData {
            (response: RestResponse) in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let result = try XMLDecoder().decode(ListObjectsResult.self, from: data)
                    success(result)
                } catch {
                    failure?(error)
                }
            case let .failure(error): failure?(error)
            }
        }
    }
}

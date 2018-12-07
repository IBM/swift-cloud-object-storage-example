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

/** COS Region Endpoints. */
public enum CosRegion: String {
    /// US Cross Region
    case usCross = "us-geo"
    /// US South
    case usSouth = "us-south"
    /// US East
    case usEast = "us-east"
    /// Europe Cross Region
    case euCross = "eu-geo"
    /// Europe Great Britain
    case euGb = "eu-gb"
    /// Europe Germany
    case euDe = "eu-de"
    /// Asia Pacific Cross Region
    case apCross = "ap-geo"
    /// Asia Pacific Japan
    case apJp = "jp-tok"

    /** Single Data Center Endpoints. */

    /// Amsterdam, Netherlands
    case ams03 = "ams03"
    /// Chennai, India
    case che01 = "che01"
    /// Melbourne, Australia
    case mel01 = "mel01"
    /// Oslo, Norway
    case osl01 = "osl01"
    /// São Paulo, Brazil
    case sao01 = "sao01"
    /// Toronto, Canada
    case tor01 = "tor01"

    /// Returns the url endpoint for the given COS region
    public func url() -> String {
        switch self {
        case .usCross: return "https://s3-api.\(self.rawValue).objectstorage.softlayer.net"
        default: return "https://s3.\(self.rawValue).objectstorage.softlayer.net"
       }
    }
}

//
//  VirtualTouristClient.swift
//  Virtual Tourist
//
//  Created by Thành Nguyễn on 8/5/24.
//

import Foundation
import Alamofire
import SwiftyJSON

class VirtualTouristClient {
    struct Auth {
        static let apiKey = "4f30cdb486af428e36dea412b6d0cde1"
        static let base = "https://api.flickr.com/services/rest"
    }
    
    static func fetchPhotos(lat: Double, lon: Double, completionHandler: @escaping (Connectivity.Status, [String]?) -> Void) {
        let url = "\(Auth.base)?api_key=\(Auth.apiKey)&method=flickr.photos.search&per_page=20&format=json&nojsoncallback=?&lat=\(lat)&lon=\(lon)&page=\((1...10).randomElement() ?? 1)"
        
        if !Connectivity.isConnectedToInternet {
            completionHandler(.notConnected, nil)
        }
        
        
        Alamofire.request(url).responseJSON { (response) in
            if((response.result.value) != nil) {
                let swiftyJsonVar = JSON(response.result.value!)
                var photosURL: [String] = []
                
                if let photos = swiftyJsonVar["photos"]["photo"].array {
                    for photo in photos {
                        let photoURL = "https://farm\(photo["farm"].stringValue).staticflickr.com/\(photo["server"].stringValue)/\(photo["id"])_\(photo["secret"]).jpg"
                        photosURL.append(photoURL)
                    }
                }
                completionHandler(.connected, photosURL)
            } else {
                completionHandler(.other, nil)
            }
        }
        
    }
}

class Connectivity {
    static var isConnectedToInternet: Bool {
        return NetworkReachabilityManager()!.isReachable
    }
    
    enum Status {
        case notConnected, connected, other
    }
}

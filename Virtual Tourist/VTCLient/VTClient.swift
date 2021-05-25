//
//  VTClient.swift
//  Virtual Tourist
//
//  Created by Ondrej Winter on 22/01/2021.
//

import Foundation
import UIKit


class VTClient {
    
    
    struct Auth {
        static let apiKey = "api_key=1c1bc94894ba10d596adc76626b89f6f"
    }
    
    
    enum Endpoints {
        
        static let base = "https://www.flickr.com/services/rest/"
        
        case getPhotos(Double, Double, Int)
        
        var stringValue: String {
            switch self {
            case .getPhotos(let lat, let lon, let numberOfPhotos): return Endpoints.base + "?method=flickr.photos.search" + "&\(Auth.apiKey)" + "&lat=\(lat)" + "&lon=\(lon)&format=json" + "&per_page=\(numberOfPhotos)"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    
    
    class func getPhotos(lat: Double, lon: Double, numberOfPhotos: Int, completion: @escaping(PhotosResults?, Error?) -> Void) {
        var request = URLRequest(url: Endpoints.getPhotos(lat, lon, numberOfPhotos).url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = URLSession.shared.dataTask(with: Endpoints.getPhotos(lat, lon, numberOfPhotos).url) { (data, response, error) in
            
            guard let data = data else {
                print(error)
              return
            }
            
            do {
                let range = 14..<data.count-1
                let newData = data.subdata(in: range)
                let jsonObject = try JSONDecoder().decode(PhotosResults.self, from: newData)
                DispatchQueue.main.async {
                    completion(jsonObject,nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil,error)
                }
                print(error)
            }
        }
        task.resume()
        
    }
    
    
    
    
    
    
    
    
    
    
    
}

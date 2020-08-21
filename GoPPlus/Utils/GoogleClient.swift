//
//  GoogleClient.swift
//  GoPPlus
//
//  Created by cmartinez on 2/15/19.
//  Copyright © 2019 GFA. All rights reserved.
//

import Foundation
import CoreLocation


struct GooglePlacesResponse : Codable {
    let results: [GooglePlaces]
}

struct GooglePlaces : Codable {
    let predictions: [GooglePrediction]
    let status: String
}

struct GooglePrediction : Codable {
    let id : String
    let place_id: String
    let structured_formatting: structuredFormatting
    
    struct structuredFormatting:Codable {
        let main_text:String
    }
}

struct GooglePlaceId: Codable {
    let result: GooglePlaceStruct
    let status: String
}

struct GooglePlaceStruct: Codable {
    let geometry: GoogleGeometry
}

struct GoogleGeometry: Codable {
    let location: GoogleLocation
}

struct GoogleLocation: Codable {
    let lat: Double
    let lng: Double
}


protocol GoogleClientRequest {

    func getGooglePlacesData(forKeyword keyword: String, using completionHandler: @escaping (GooglePlacesResponse) -> ())
    func getGooglePlaceId(forPlaceId placeid: String, using completionHandler: @escaping (GooglePlaceId) -> ())
    
}

class GoogleClient: GoogleClientRequest {
    
    //async call to make a request to google for JSON
    func getGooglePlacesData(forKeyword keyword: String, using completionHandler: @escaping (GooglePlacesResponse) -> ())  {
        
        Constants.getAutocomplete(parameters: ["input" : keyword, "key": Constants.APIKEY]) { (result) in
            
            if result == nil {
                completionHandler(GooglePlacesResponse(results: []))
            } else {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: result as Any, options: [])
                    let googleresults =  try JSONDecoder().decode(GooglePlaces.self, from: jsonData)
                    
                    completionHandler(GooglePlacesResponse(results: [googleresults]))
                    return
                } catch {
                   completionHandler(GooglePlacesResponse(results: []))
                }
            }
        }
    }
    
    //getPlaceId
    
    
    func getGooglePlaceId(forPlaceId placeid: String, using completionHandler: @escaping (GooglePlaceId) -> ())  {
        
        Constants.getPlaceId(parameters: ["placeid" : placeid, "key": Constants.APIKEY]) { (result) in
            
            if result == nil {
                completionHandler(GooglePlaceId(result: GooglePlaceStruct(geometry: GoogleGeometry(location: GoogleLocation(lat: 0, lng: 0))), status: "NO"))
            } else {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: result as Any, options: [])
                    let place =  try JSONDecoder().decode(GooglePlaceId.self, from: jsonData)
                    
                    completionHandler(place)
                    return
                } catch {
                    completionHandler(GooglePlaceId(result: GooglePlaceStruct(geometry: GoogleGeometry(location: GoogleLocation(lat: 0, lng: 0))), status: "NO"))
                }
            }
        }
    }
    
}

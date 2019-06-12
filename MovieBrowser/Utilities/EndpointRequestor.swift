//
//  EndpointRequestor.swift
//  MovieBrowser
//
//  Created by Matthew Certain on 6/11/19.
//  Copyright © 2019 M. Certain. All rights reserved.
//

import Foundation
import UIKit

let MOVIEDB_LISTING_PREFIX:String = "https://api.themoviedb.org/3/movie/popular?api_key=ac975fc8b7261ca68365d2cf95286764&language=en-US&page="

// The Interim String should be the Movie DB ID
let EXTERNAL_ID_QUERY_PREFIX:String = "https://api.themoviedb.org/3/movie/"
let EXTERNAL_ID_QUERY_SUFFIX:String = "/external_ids?api_key=ac975fc8b7261ca68365d2cf95286764"

// The Final String should be the Movie DB ID
let POSTER_IMAGE_PREFIX:String = "https://image.tmdb.org/t/p"
let POSTER_IMAGE_FULL_SUFFIX:String = "/original"
let POSTER_IMAGE_THUMB_SUFFIX:String = "/w500"

// The Interim string should be the IMDB ID
let IMDB_URL_PREFIX:String = "https://www.imdb.com/title/"
let IMDB_URL_SUFFIX:String = "/"

// The Interim string should be the movie title with spaces replaced by +
let AMAZON_URL_PREFIX:String = "https://www.amazon.com/s?k="
let AMAZON_URL_SUFFIX:String = "&i=instant-video&tag=ftrx-20"

enum MovieDataEndpoint: Int {
    case MOVIE_LISTING
    case EXTERNAL_ID_QUERY
    case POSTER_IMAGE_THUMBNAIL
}

enum ExternalLinkEndpoint: Int {
    case OPEN_IMDB_DETAILS
    case OPEN_AMAZON_DETAILS
}

class EndpointRequestor {
    
    static func openMovieLink(withEndpoint: ExternalLinkEndpoint, queryString: String?) {
        guard queryString != nil else {
            return
        }
        
        var trackLocation: URL?
        switch withEndpoint {
        case .OPEN_IMDB_DETAILS:
            trackLocation = URL(string: IMDB_URL_PREFIX + queryString! + IMDB_URL_SUFFIX)
        case .OPEN_AMAZON_DETAILS:
            trackLocation = URL(string: AMAZON_URL_PREFIX + queryString! + AMAZON_URL_SUFFIX)
        }
        
        guard trackLocation != nil else {
            return
        }
        UIApplication.shared.open(trackLocation!, options: [:])
    }
    
    static func requestEndpointData(endpoint: MovieDataEndpoint,
                                    withUIViewController: UIViewController,
                                    errorHandler: (() -> Void)?,
                                    successHandler: ((_ receivedData: Data?, _ withArgument: AnyObject?) -> Void)?,
                                    busyTheView: Bool,
                                    withArgument: AnyObject?=nil) {
        var remoteLocation: URL?
        switch endpoint {
        case .MOVIE_LISTING:
            remoteLocation = URL(string: MOVIEDB_LISTING_PREFIX + String(withArgument as! Int))
        case .EXTERNAL_ID_QUERY:
            remoteLocation = URL(string: EXTERNAL_ID_QUERY_PREFIX + (withArgument as! String) + EXTERNAL_ID_QUERY_SUFFIX)
        case .POSTER_IMAGE_THUMBNAIL:
            remoteLocation = MovieDataManager.GetInstance()?.getMovieDetails(atIndex: (withArgument as! Int))?.getPosterImageThumbURL()
        }
        
        guard remoteLocation != nil else {
            return
        }
        
        // Just incase it takes a while to get a response, busy the view so the user knows something
        // is happening
        var busyViewOverlay: UIViewController?
        if(busyTheView == true) {
            busyViewOverlay = withUIViewController.busyTheViewWithIndicator(currentUIViewController: withUIViewController)
        }
        let task = URLSession.shared.dataTask(with: remoteLocation!) {(data, response, error) in
            // Once the response comes back, then the view can be unbusied and updated
            if(busyTheView == true) {
                withUIViewController.unbusyTheViewWithIndicator(busyView: busyViewOverlay)
            }
            
            // For issues, dispatch the default view indicating the information is unavailable
            guard error == nil else {
                print("URL Request returned with error.")
                errorHandler?()
                return
            }
            guard let content = data else {
                print("There was no data at the requested URL.")
                errorHandler?()
                return
            }
            
            successHandler?(content, withArgument)
        }
        task.resume()
    }
}

//
//  MovieDBEndpointDescriptor.swift
//  MovieBrowser
//
//  Created by Matthew Certain on 6/22/19.
//  Copyright © 2019 M. Certain. All rights reserved.
//

import Foundation

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
    case OPEN_IMDB_DETAILS
    case OPEN_AMAZON_DETAILS
}

class MovieDBEndpointDescriptor : EndpointDescriptorBase {
    
    let endpointType: Any
    
    init(endpoint: MovieDataEndpoint) {
        endpointType = endpoint
    }
    
    func getTargetURL(withArgument: AnyObject?) -> URL? {
        var remoteLocation: URL?
        let endpointType = self.endpointType as! MovieDataEndpoint
        switch endpointType {
        case .MOVIE_LISTING:
            remoteLocation = URL(string: MOVIEDB_LISTING_PREFIX + String(withArgument as! Int))
        case .EXTERNAL_ID_QUERY:
            remoteLocation = URL(string: EXTERNAL_ID_QUERY_PREFIX + (withArgument as! String) + EXTERNAL_ID_QUERY_SUFFIX)
        case .POSTER_IMAGE_THUMBNAIL:
            remoteLocation = (withArgument as! URL)
        case .OPEN_IMDB_DETAILS:
            remoteLocation = URL(string: IMDB_URL_PREFIX + (withArgument as! String) + IMDB_URL_SUFFIX)
        case .OPEN_AMAZON_DETAILS:
            remoteLocation = URL(string: AMAZON_URL_PREFIX + (withArgument as! String) + AMAZON_URL_SUFFIX)
        }
        return remoteLocation
    }
}

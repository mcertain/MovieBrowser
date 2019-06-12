//
//  MovieDataManager.swift
//  MovieBrowser
//
//  Created by Matthew Certain on 6/11/19.
//  Copyright © 2019 M. Certain. All rights reserved.
//

import Foundation
import UIKit

let RESULTS_PER_PAGE: Int = 20

struct ResultsPage: Decodable, Equatable  {
    let page:          Int
    let total_pages:   Int
    let total_results: Int
    var results:       [MovieItem]
}

struct MovieItem: Decodable, Equatable {
    let adult:             Bool?
    let backdrop_path:     String?
    let genre_ids:         [Int]?
    let id:                Int
    let original_language: String?
    let original_title:    String?
    let overview:          String
    let popularity:        Float64
    let poster_path:       String?
    let release_date:      String?
    let title:             String
    let video:             Bool?
    let vote_average:      Float64
    let vote_count:        Int
    var imagePosterData:   Data?
    var external_ids:      ExternalIDs?
    
    func getMovieIDString() -> String {
        return String(self.id)
    }
    
    func getMovieTitleQueryString() -> String? {
        var movieTitle: String? = self.title 
        movieTitle = movieTitle!.replacingOccurrences(of: "\\s+", with: "+", options: .regularExpression)
        return movieTitle
    }
    
    func getUIImageData() -> UIImage? {
        guard imagePosterData != nil else {
            return nil
        }
        return UIImage(data: imagePosterData!)
    }
    
    func getVoteStarRating() -> String? {
        let simplifedVote = Int((self.vote_average)/2)
        var starRatingString: String
        switch simplifedVote {
        case 0:
            starRatingString = "☆☆☆☆☆"
        case 1:
            starRatingString = "★☆☆☆☆"
        case 2:
            starRatingString = "★★☆☆☆"
        case 3:
            starRatingString = "★★★☆☆"
        case 4:
            starRatingString = "★★★★☆"
        case 5:
            starRatingString = "★★★★★"
        default:
            starRatingString = "☆☆☆☆☆"
        }
        return starRatingString
    }
    
    func getMovieTitle() -> String? {
        return self.title
    }
    
    func getReleaseDate() -> String? {
        return self.release_date
    }
    
    func getNumberUserVotes() -> String? {
        return String(self.vote_count)
    }
    
    func getExternalIDs() -> ExternalIDs? {
        return self.external_ids
    }
    
    func getPosterImageFullURL() -> URL? {
        guard self.poster_path != nil else {
            return nil
        }
        return URL(string: POSTER_IMAGE_PREFIX + POSTER_IMAGE_THUMB_SUFFIX + (self.poster_path!) )
    }
    
    func getPosterImageThumbURL() -> URL? {
        guard self.poster_path != nil else {
            return nil
        }
        return URL(string: POSTER_IMAGE_PREFIX + POSTER_IMAGE_FULL_SUFFIX + (self.poster_path!) )
    }
}

struct ExternalIDs: Decodable, Equatable {
    let id:         Int
    let imdb_id:    String
}

class MovieDataManager {
    
    // MovieDataManager should be singleton since we only need one instance for
    // helper parsing functions and to store the Movie List Items
    static var singletonInstance:MovieDataManager? = nil
    fileprivate var cachedPages: [ResultsPage?] = []
    fileprivate var watchList: [MovieItem] = []

    private init() { }
    
    static func GetInstance() ->MovieDataManager? {
        if(MovieDataManager.singletonInstance == nil) {
            MovieDataManager.singletonInstance = MovieDataManager()
        }
        return MovieDataManager.singletonInstance
    }
    
    func storeMovieData(receivedJSONData: Data?, forPage: Int) -> Bool {
        var receivedPage: ResultsPage
        if(receivedJSONData != nil) {
            do {  
                receivedPage = try JSONDecoder().decode(ResultsPage.self, from: receivedJSONData!)
            }
            catch let decodeError {
                print("Failed to decode Movie DB JSON Data: \(decodeError)")
                return false
            }
            
            if(cachedPages.count == (forPage-1)) {
                cachedPages.append(receivedPage)
            }
        }
        return true
    }
    
    func storeExternalIDs(atIndex: Int, receivedJSONData: Data?) -> Bool {
        if(receivedJSONData != nil) {
            do {
                let externalIDs = try JSONDecoder().decode(ExternalIDs.self, from: receivedJSONData!)
                self.setExternalIDs(atIndex: atIndex, withData: externalIDs)
            }
            catch let decodeError {
                print("Failed to decode External ID JSON Data: \(decodeError)")
                return false
            }
        }
        return true
    }
    
    func getMovieCount() -> Int {
        guard cachedPages.indices.contains(0) == true else {
            return 0
        }
        
        return cachedPages[0]?.total_results ?? 0
    }
    
    func getPageCount() -> Int {        
        return cachedPages.count
    }
    
    func pageCacheExists(atPage: Int) -> Bool {
        return cachedPages.indices.contains(atPage-1)
    }
    
    func getMovieDetails(atIndex: Int) -> MovieItem? {
        let pageCount = atIndex / RESULTS_PER_PAGE
        let pageIdx = atIndex % RESULTS_PER_PAGE
        
        guard cachedPages.indices.contains(pageCount) == true else {
            return nil
        }
        guard cachedPages[pageCount]?.results[pageIdx] != nil else {
            return nil
        }
        return cachedPages[pageCount]?.results[pageIdx]
    }
    
    func setPosterImage(atIndex: Int, withData: Data) {
        let pageCount = atIndex / RESULTS_PER_PAGE
        let pageIdx = atIndex % RESULTS_PER_PAGE
        cachedPages[pageCount]?.results[pageIdx].imagePosterData = withData
    }
    
    func setExternalIDs(atIndex: Int, withData: ExternalIDs) {
        let pageCount = atIndex / RESULTS_PER_PAGE
        let pageIdx = atIndex % RESULTS_PER_PAGE
        cachedPages[pageCount]?.results[pageIdx].external_ids = withData
    }
    
    func GetWatchList() -> [MovieItem] {
        return watchList
    }
    func GetWatchListCount() -> Int {
        return watchList.count
    }
    func AddToWatchList(newItem: MovieItem) {
        watchList.append(newItem)
    }
    
    func RemoveFromWatchList(withID: String) {
        let updateWatchList = watchList.filter { (item) -> Bool in
            return (String(item.id) != withID)
        }
        watchList = updateWatchList
    }
    
    func ExistsInWatchList(withID: String) -> Bool {
        let foundItems = watchList.filter { (item) -> Bool in
            return (String(item.id) == withID)
        }
        if(foundItems.count != 0) {
            return true
        }
        else {
            return false
        }
    }
    
    func GetWatchListItem(atIndex: Int) -> MovieItem {
        return watchList[atIndex]
    }
}

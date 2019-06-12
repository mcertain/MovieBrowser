//
//  MovieDetailsController.swift
//  MovieBrowser
//
//  Created by Matthew Certain on 6/11/19.
//  Copyright © 2019 M. Certain. All rights reserved.
//

import Foundation
import UIKit

let addToWatchListString: String = "Add to Watchlist ♡"
let removeToWatchListString: String = "Remove From Watchlist ♡"

class MovieDetailsController : UIViewController, UINavigationControllerDelegate {
    
    var movieID: String?
    var movieTableViewIdx: Int?
    @IBOutlet var movieTitleLabel: UILabel!
    @IBOutlet var movieDetailsLabel: UITextView!
    @IBOutlet var movieCoverImageView: UIImageView!
    @IBOutlet var imdbButton: UIButton!
    @IBOutlet var amazonButton: UIButton!
    @IBOutlet var watchListButton: UIButton!
    
    @IBAction func imdbButtonAction(_ sender: Any) {
        guard let movieDetails = MovieDataManager.GetInstance()?.getMovieDetails(atIndex: movieTableViewIdx ?? 0) else {
            return
        }
        EndpointRequestor.openMovieLink(withEndpoint: .OPEN_IMDB_DETAILS,
                                        queryString: movieDetails.external_ids!.imdb_id)
    }
    
    @IBAction func amazonButtonAction(_ sender: Any) {
        guard let movieDetails = MovieDataManager.GetInstance()?.getMovieDetails(atIndex: movieTableViewIdx ?? 0) else {
            return
        }
        EndpointRequestor.openMovieLink(withEndpoint: .OPEN_AMAZON_DETAILS,
                                        queryString: movieDetails.getMovieTitleQueryString()!)
    }
    
    @IBAction func addToWatchListButtonAction(_ sender: Any) {
        let pMovieDataManager = MovieDataManager.GetInstance()
        guard let movieDetails = pMovieDataManager?.getMovieDetails(atIndex: movieTableViewIdx ?? 0) else {
            return
        }
        
        let pressedButton = (sender as! UIButton)
        if(pressedButton.tag == 0) {
            pMovieDataManager?.AddToWatchList(newItem: movieDetails)
            pressedButton.tag = 1
            pressedButton.setTitle(removeToWatchListString, for: .normal)
        }
        else {
            pMovieDataManager?.RemoveFromWatchList(withID: self.movieID!)
            pressedButton.tag = 0
            pressedButton.setTitle(addToWatchListString, for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchMovieDetails()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Register network change events and attempt to fetch the movie details when the view loads
        NetworkAvailability.setupReachability(controller: self, selector: #selector(self.reachabilityChanged(note:)) )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // When not visible, then we don't need to get this notification
        super.viewWillDisappear(animated)
        NetworkAvailability.removeReachability(controller: self, selector: #selector(self.reachabilityChanged(note:)) )
    }
    
    @objc func reachabilityChanged(note: Notification) {
        
        let reachability = note.object as! Reachability
        
        if(reachability.connection != .none) {
            // When the network returns, try to fetch (or refresh the current) movie details
            self.fetchMovieDetailsAfterNetworkReturned()
        }
        else {
            // When the network is disconnected, then show an alert to the user
            NetworkAvailability.displayNetworkDisconnectedAlert(currentUIViewController: self)
        }
    }

    func fetchMovieDetailsAfterNetworkReturned() {
        // When the network returns, wait momentarily and then try to fetch the movie details again
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.fetchMovieDetails()
        }
    }
    
    func setupDefaultView() {
        // Used when the network is down and the cache can't be updated with a new entry
        self.movieTitleLabel.text = "Unavailable"
        self.movieDetailsLabel.text = "Try again later."
        self.movieCoverImageView.image = UIImage(named: "NoConnection")
        self.amazonButton.isHidden = true
        self.imdbButton.isHidden = true
        self.watchListButton.isHidden = true
    }
    
    func setupView(withDetails: MovieItem) {
        // Used when there is a valid cache entry to display movie details
        self.movieTitleLabel.text = withDetails.title
        self.movieDetailsLabel.text = withDetails.overview
        self.movieCoverImageView.image = withDetails.getUIImageData()
        
        let pMovieDataManager = MovieDataManager.GetInstance()
        let existsOnWatchList = pMovieDataManager?.ExistsInWatchList(withID: self.movieID!)
        if(existsOnWatchList == true) {
            self.watchListButton.tag = 1
            self.watchListButton.setTitle(removeToWatchListString, for: .normal)
        }
        else {
            self.watchListButton.tag = 0
            self.watchListButton.setTitle(addToWatchListString, for: .normal)
        }
    }
    
    func setupExternalLinkButtons(withDetails: MovieItem) {
        DispatchQueue.main.async {
            if(withDetails.external_ids == nil) {
                self.amazonButton.isHidden = true
                self.imdbButton.isHidden = true
            }
            else {
                self.amazonButton.isHidden = false
                self.imdbButton.isHidden = false
            }
        }
    }
    
    func dispatchViewUpdate () {
        DispatchQueue.main.async {
            // If the movie details are missing, then just show the default view
            // indicating the information is unavailable
            let pMovieDataManager = MovieDataManager.GetInstance()
            guard let movieDetails = pMovieDataManager?.getMovieDetails(atIndex: self.movieTableViewIdx ?? 0) else {
                self.setupDefaultView()
                return
            }
            // Otherwise, take the information from cache and show the movie details
            self.setupView(withDetails: movieDetails)
        }
    }
    
    func requestMovieDetails() {
        // Fetch the External Link ID Data
        self.fetchExternalIDs(atIndex: movieTableViewIdx!, withID: movieID!)
        
        // And then update the view with what was just stored in cache
        self.dispatchViewUpdate()
    }
    
    func fetchMovieDetails() {
        // When the movie ID is valid
        if(movieID != nil && movieID != "") {
            // When the network is available, request any additional movie data
            if( NetworkAvailability.networkAvailable() == true) {
                self.requestMovieDetails()
            }
            else {
                // Otherwise, since the network is down just show what's cached already
                self.dispatchViewUpdate()
            }
        }
    }
    
    func fetchExternalIDs(atIndex: Int, withID: String) {
        let pMovieDataManager = MovieDataManager.GetInstance()
        
        // If the externalIDs haven't be stored in cache yet, then fetch and store them
        let movieDetails = pMovieDataManager?.getMovieDetails(atIndex: atIndex)
        let externalIDs = movieDetails?.getExternalIDs()
        if(externalIDs == nil) {
            let successHandler = { (receivedData: Data?, withArgument: AnyObject?) -> Void in
                guard let content = receivedData else {
                    print("There was no data at the requested URL.")
                    return
                }
                
                // Store the External IDs in the Movie Data Manager's cache
                MovieDataManager.GetInstance()?.storeExternalIDs(atIndex: atIndex, receivedJSONData: content)
                self.setupExternalLinkButtons(withDetails: (pMovieDataManager?.getMovieDetails(atIndex: atIndex)!)!)
            }
            
            EndpointRequestor.requestEndpointData(endpoint: .EXTERNAL_ID_QUERY,
                                                  withUIViewController: self,
                                                  errorHandler: nil,
                                                  successHandler: successHandler,
                                                  busyTheView: true,
                                                  withArgument: withID as AnyObject)
        }
        else {
            // Otherwise, display links with ID from cache
            self.setupExternalLinkButtons(withDetails: movieDetails!)
        }
    }
}

//
//  AvailableMovieController.swift
//  MovieBrowser
//
//  Created by Matthew Certain on 6/11/19.
//  Copyright © 2019 M. Certain. All rights reserved.
//

import UIKit

class AvailableMovieController: UITableViewController, UITableViewDataSourcePrefetching {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupTableView()
        
        // Register network change events and attempt to fetch the movie details when the view loads
        NetworkAvailability.setupReachability(controller: self, selector: #selector(self.reachabilityChanged(note:)) )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // When not visible, then we don't need to get this notification
        super.viewWillDisappear(animated)
        NetworkAvailability.removeReachability(controller: self, selector: #selector(self.reachabilityChanged(note:)) )
    }
    
    func setupTableView() {
        tableView.prefetchDataSource = self
        //tableView.register(MovieListCell.self, forCellReuseIdentifier: "MovieListCell")
        tableView.register(UINib(nibName: "MovieListCell", bundle: nil), forCellReuseIdentifier: "MovieListCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = MOVIE_LIST_CELL_HEIGHT
    }
    
    @objc func reachabilityChanged(note: Notification) {
        let reachability = note.object as! Reachability
        if(reachability.connection != .none) {
            // Once the network is confirmed to be available, then fetch the first page of movie list data
            self.fetchMovieData(atPage: 1)
        }
        else {
            // When the network is disconnected, then show an alert to the user
            NetworkAvailability.displayNetworkDisconnectedAlert(currentUIViewController: self)
        }
    }
    
    func fetchMovieData(atPage: Int) {
        let pMovieDataManager = MovieDataManager.GetInstance()
        
        // If the page isn't in cache, then go ahead and download it
        if((pMovieDataManager?.pageCacheExists(atPage: atPage))! == false) {
            let successHandler = { (receivedData: Data?, withArgument: AnyObject?) -> Void in
                let fetchedPageIdx = (withArgument as! Int)
                guard (pMovieDataManager?.storeMovieData(receivedJSONData: receivedData,
                                                         forPage: fetchedPageIdx))! else {
                    print("JSON data parsing failed.")
                    return
                }
                
                // When the data is successfully retrieved and stored, then reload the table data
                // from the Movie Data Manager's cache
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        
            EndpointRequestor.requestEndpointData(endpoint: .MOVIE_LISTING,
                                                  withUIViewController: self,
                                                  errorHandler: nil,
                                                  successHandler: successHandler,
                                                  busyTheView: true,
                                                  withArgument: atPage as AnyObject)
        }
    }
    
    func fetchMoviePosterImage(forCell: MovieListCell, atIndex: Int, withID: String) {
        let pMovieDataManager = MovieDataManager.GetInstance()
        
        // If the movie cover image hasn't be stored in cache yet, then fetch and store it
        let posterImage = pMovieDataManager?.getMovieDetails(atIndex: atIndex)?.getUIImageData()
        if(posterImage == nil) {
            let successHandler = { (receivedData: Data?, withArgument: AnyObject?) -> Void in
                guard let content = receivedData else {
                    print("There was no data at the requested URL.")
                    return
                }
                
                // Store the Movie Cover Image in the Movie Data Manager's cache
                MovieDataManager.GetInstance()?.setPosterImage(atIndex: atIndex, withData: content)
                
                // Then update only the cell that needs to display the movie cover image
                DispatchQueue.main.async {
                    forCell.movieCoverImage.image = UIImage(data: content)
                }
            }
            
            EndpointRequestor.requestEndpointData(endpoint: .POSTER_IMAGE_THUMBNAIL,
                                                  withUIViewController: self,
                                                  errorHandler: nil,
                                                  successHandler: successHandler,
                                                  busyTheView: false,
                                                  withArgument: atIndex as AnyObject)
        }
        else {
            // Otherwise, if it's already cached then display it
            forCell.movieCoverImage.image = posterImage
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (MovieDataManager.GetInstance()?.getMovieCount())!
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return MOVIE_LIST_CELL_HEIGHT
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: MovieListCell
        let idx:Int = indexPath.row
        
        // Load the default cell layout and populate it
        cell = tableView.dequeueReusableCell(withIdentifier: "MovieListCell", for: indexPath) as! MovieListCell
        
        let pMovieDataManager = MovieDataManager.GetInstance()
        let movieItem = pMovieDataManager?.getMovieDetails(atIndex: idx)
        if(movieItem != nil) {
            cell.movieTitle.text = String(idx+1) + ". " + (movieItem?.getMovieTitle())!
            cell.releaseDate.text = movieItem?.getReleaseDate()
            cell.voteStarRating.text = movieItem?.getVoteStarRating()
            cell.numberUserVotes.text = movieItem?.getNumberUserVotes()
            cell.movieCoverImage.image = movieItem?.getUIImageData()
            let movieID: String? = pMovieDataManager?.getMovieDetails(atIndex: idx)?.getMovieIDString()
            self.fetchMoviePosterImage(forCell: cell, atIndex: idx,
                                      withID: movieID!)
        }
        else {
            print("Movie Item Data not cached yet.")
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        let finalPrefetchItem = indexPaths[indexPaths.count-1].row
        let prefetchPage = (finalPrefetchItem / RESULTS_PER_PAGE) + 1
        
        // Load all cached pages prior to the current one that haven't been loaded yet
        let pMovieDataManager = MovieDataManager.GetInstance()
        var pageFetchCount: Int = pMovieDataManager?.getPageCount() ?? 0
        while(pageFetchCount <= prefetchPage) {
            self.fetchMovieData(atPage: pageFetchCount)
            pageFetchCount = pageFetchCount+1
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // When a table cell is touched, then load and open movie details view for movie selected
        let mainStoryBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
        if let pMovieDetailsController = mainStoryBoard.instantiateViewController(withIdentifier: "MovieDetailsController") as? MovieDetailsController {
            let idx:Int = indexPath.row
            let pMovieDataManager = MovieDataManager.GetInstance()
            pMovieDetailsController.movieID = pMovieDataManager?.getMovieDetails(atIndex: idx)?.getMovieIDString()
            pMovieDetailsController.movieTableViewIdx = idx
            navigationController?.pushViewController(pMovieDetailsController, animated: true)
        }
        else {
            print("Could not load the Chat Message Controller view controller")
            return
        }
    }


}


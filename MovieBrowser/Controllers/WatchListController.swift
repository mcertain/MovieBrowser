//
//  WatchListController.swift
//  MovieBrowser
//
//  Created by Matthew Certain on 6/11/19.
//  Copyright © 2019 M. Certain. All rights reserved.
//

import UIKit

class WatchListController: UITableViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Register network change events and attempt to fetch the movie details when the view loads
        NetworkAvailability.setupReachability(controller: self, selector: #selector(self.reachabilityChanged(note:)) )
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // When not visible, then we don't need to get this notification
        super.viewWillDisappear(animated)
        NetworkAvailability.removeReachability(controller: self, selector: #selector(self.reachabilityChanged(note:)) )
    }
    
    @objc func reachabilityChanged(note: Notification) {
        
        let reachability = note.object as! Reachability
        if(reachability.connection != .none) {
            // Once the network is confirmed to be available, then reload the movie watch list data
            self.tableView.reloadData()
        }
        else {
            // When the network is disconnected, then show an alert to the user
            NetworkAvailability.displayNetworkDisconnectedAlert(currentUIViewController: self)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (MovieDataManager.GetInstance()?.GetWatchListCount())!
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return MOVIE_LIST_CELL_HEIGHT
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: MovieListCell
        let idx:Int = indexPath.row
        let pMovieDataManager = MovieDataManager.GetInstance()
        
        // Load the default cell layout and populate it
        cell = Bundle.main.loadNibNamed("MovieListCell", owner: self, options: nil)?.first as! MovieListCell
        
        let movieItem = pMovieDataManager?.GetWatchListItem(atIndex: idx)
        cell.movieTitle.text = movieItem?.getMovieTitle()
        cell.releaseDate.text = movieItem?.getReleaseDate()
        cell.voteStarRating.text = movieItem?.getVoteStarRating()
        cell.numberUserVotes.text = movieItem?.getNumberUserVotes()
        cell.movieCoverImage.image = movieItem?.getUIImageData()

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // When a table cell is touched, then load and open movie details view for movie selected
        let mainStoryBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        if let pMovieDetailsController = mainStoryBoard.instantiateViewController(withIdentifier: "MovieDetailsController") as? MovieDetailsController {
            let idx:Int = indexPath.row
            let pMovieDataManager = MovieDataManager.GetInstance()
            pMovieDetailsController.movieID = pMovieDataManager?.GetWatchListItem(atIndex: idx).getMovieIDString()
            pMovieDetailsController.movieTableViewIdx = idx
            navigationController?.pushViewController(pMovieDetailsController, animated: true)
        }
        else {
            print("Could not load the Chat Message Controller view controller")
            return
        }
    }


}


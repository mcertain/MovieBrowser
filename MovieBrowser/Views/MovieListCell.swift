//
//  MovieListCell.swift
//  MovieBrowser
//
//  Created by Matthew Certain on 6/11/19.
//  Copyright © 2019 M. Certain. All rights reserved.
//

import Foundation
import UIKit

let MOVIE_LIST_CELL_HEIGHT: CGFloat = 90

class MovieListCell : UITableViewCell {
    @IBOutlet var movieCoverImage: UIImageView!
    @IBOutlet var movieTitle: UILabel!
    @IBOutlet var releaseDate: UILabel!
    @IBOutlet var voteStarRating: UILabel!
    @IBOutlet var numberUserVotes: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        movieCoverImage.image = nil
        movieTitle.text = ""
        releaseDate.text = ""
        voteStarRating.text = ""
        numberUserVotes.text = ""
    }
}

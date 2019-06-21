//
//  EndpointDescriptorBase.swift
//  MovieBrowser
//
//  Created by Matthew Certain on 6/22/19.
//  Copyright © 2019 M. Certain. All rights reserved.
//

import Foundation

protocol EndpointDescriptorBase {
    func getTargetURL(withArgument: AnyObject?) -> URL?
}

//
//  EndpointRequestor.swift
//  MovieBrowser
//
//  Created by Matthew Certain on 6/11/19.
//  Copyright © 2019 M. Certain. All rights reserved.
//

import Foundation
import UIKit

class EndpointRequestor {
    /// We store all ongoing tasks here to avoid duplicating tasks.
    static var tasks = [URLSessionTask]()
    
    static func openExternalLink(endpointDescriptor: EndpointDescriptorBase, withTargetArgument: AnyObject?=nil) {
        guard withTargetArgument != nil else {
            return
        }
        
        // Use the provide endpoint descriptor to get the target URL using the supplied target arguments
        let remoteLocation: URL? = endpointDescriptor.getTargetURL(withArgument: withTargetArgument as AnyObject)
        guard remoteLocation != nil else {
            return
        }
        
        guard remoteLocation != nil else {
            return
        }
        UIApplication.shared.open(remoteLocation!, options: [:])
    }
    
    static func requestEndpointData(endpointDescriptor: EndpointDescriptorBase,
                                    withUIViewController: UIViewController,
                                    errorHandler: (() -> Void)?,
                                    successHandler: ((_ receivedData: Data?, _ withArgument: AnyObject?) -> Void)?,
                                    busyTheView: Bool,
                                    withTargetArgument: AnyObject?=nil) {
        
        // Use the provide endpoint descriptor to get the target URL using the supplied target arguments
        let remoteLocation: URL? = endpointDescriptor.getTargetURL(withArgument: withTargetArgument)
        guard remoteLocation != nil else {
            return
        }
        
        // Don't attempt to fetch the same resource twice while one fetch request is pending
        guard tasks.index(where: { $0.originalRequest?.url == remoteLocation }) == nil else {
            print("Attempted to fetch the same resource more than once before the previous fetch had completed.")
            return
        }
        
        // Just incase it takes a while to get a response, busy the view so the user knows something
        // is happening
        var busyViewOverlay: UIViewController?
        if(busyTheView == true) {
            busyViewOverlay = withUIViewController.busyTheViewWithIndicator(currentUIViewController: withUIViewController)
        }
        
        let task = URLSession.shared.dataTask(with: remoteLocation!) {(data, response, error) in
            // Find and remove task reference once the content processing is done
            guard let taskIndex = tasks.index(where: { $0.originalRequest?.url == remoteLocation }) else {
                print("Task for URL was not found.")
                return
            }
            
            // Once the response comes back, then the view can be unbusied and updated
            if(busyTheView == true) {
                withUIViewController.unbusyTheViewWithIndicator(currentUIViewController: withUIViewController, busyView: busyViewOverlay)
            }
            
            // For issues, dispatch the default view indicating the information is unavailable
            guard error == nil else {
                print("URL Request returned with error.")
                errorHandler?()
                tasks.remove(at: taskIndex)
                return
            }
            guard let content = data else {
                print("There was no data at the requested URL.")
                errorHandler?()
                tasks.remove(at: taskIndex)
                return
            }
            
            successHandler?(content, withTargetArgument)
            tasks.remove(at: taskIndex)
        }
        task.resume()
        tasks.append(task)
    }
}

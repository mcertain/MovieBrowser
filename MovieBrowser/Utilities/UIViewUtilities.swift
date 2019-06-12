//
//  UIViewUtilities.swift
//  MovieBrowser
//
//  Created by Matthew Certain on 4/11/19.
//  Copyright © 2019 M. Certain. All rights reserved.
//

import Foundation
import UIKit

// Utility help class to display busy view overlay when waiting on network response
class SpinnerViewController: UIViewController {
    var spinner = UIActivityIndicatorView(style: .whiteLarge)
    var currentUIViewController: UIViewController?
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.7)
        
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        view.addSubview(spinner)
        
        spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    static func createSpinnerView(currentUIViewController: UIViewController?) ->UIViewController?  {
        let child = SpinnerViewController()
        
        DispatchQueue.main.async {
            // Add the spinner to the view controller
            currentUIViewController?.addChild(child)
            child.view.frame = (currentUIViewController?.view.frame)!
            currentUIViewController?.view.addSubview(child.view)
            child.didMove(toParent: currentUIViewController)
        }
        
        return child as UIViewController
    }
    
    static func stopSpinnerView(busyView: UIViewController?)  {
        let child = busyView as! SpinnerViewController
        DispatchQueue.main.async {
            // Remove the spinner view controller
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
    }
}

extension UIViewController {
    
    // Extensions to busy/unbusy any UIViewController
    func busyTheViewWithIndicator(currentUIViewController: UIViewController?) ->UIViewController? {
        return SpinnerViewController.createSpinnerView(currentUIViewController: currentUIViewController)
    }
    
    func unbusyTheViewWithIndicator(busyView: UIViewController?) {
        SpinnerViewController.stopSpinnerView(busyView: busyView)
    }
}

extension UIView {
    
    // This extension makes setting anchors much easier with one API
    // Parameters with a ?= are optional and can be checked for existance
    func setAnchors(top:    NSLayoutYAxisAnchor?=nil,   topPad:     CGFloat?=0,
                    bottom: NSLayoutYAxisAnchor?=nil,   bottomPad:  CGFloat?=0,
                    left:   NSLayoutXAxisAnchor?=nil,   leftPad:    CGFloat?=0,
                    right:  NSLayoutXAxisAnchor?=nil,   rightPad:   CGFloat?=0,
                    centerVertical:   NSLayoutYAxisAnchor?=nil,
                    centerHorizontal: NSLayoutXAxisAnchor?=nil,
                    height: CGFloat?=0,
                    width:  CGFloat?=0)
    {
        // Turn off auto contraints so that we can define our own
        self.translatesAutoresizingMaskIntoConstraints = false;
        
        if let actualTop = top, let actualTopPad = topPad {
            // Anchored the top and pad with an offset from the anchor point
            self.topAnchor.constraint(equalTo: actualTop, constant: actualTopPad).isActive = true;
        }
        
        if let actualBottom = bottom, let actualBottomPad = bottomPad  {
            // Anchored the bottom and pad with an offset from the anchor point
            self.bottomAnchor.constraint(equalTo: actualBottom, constant: -actualBottomPad).isActive = true
        }
        
        if let actualLeft = left, let actualLeftPad = leftPad   {
            // Anchored the left and pad with an offset from the anchor point
            self.leftAnchor.constraint(equalTo: actualLeft, constant: actualLeftPad).isActive = true
        }
        
        if let actualRight = right, let actualRightPad = rightPad {
            // Anchored the right and pad with an offset from the anchor point
            self.rightAnchor.constraint(equalTo: actualRight, constant: -actualRightPad).isActive = true
        }
        
        if let actualCenterV = centerVertical {
            // Define the horizontal center position on the screen
            self.centerYAnchor.constraint(equalTo: actualCenterV).isActive = true
        }
        
        if let actualCenterH = centerHorizontal {
            // Define the horizontal center position on the screen
            self.centerXAnchor.constraint(equalTo: actualCenterH).isActive = true
        }
        
        if let actualHeight = height {
            if actualHeight > 0 {
                // Define the height of the view component as long as the parameter is valid
                self.heightAnchor.constraint(equalToConstant: actualHeight).isActive = true
            }
        }
        
        if let actualWidth = width {
            if actualWidth > 0 {
                // Define the width of the view component as long as the parameter is valid
                self.widthAnchor.constraint(equalToConstant: actualWidth).isActive = true
            }
        }
    }
    
}

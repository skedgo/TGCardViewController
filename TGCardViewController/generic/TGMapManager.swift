//
//  TGMapManager.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import MapKit

class TGMapManager {
  
  enum Zoom: Double {
    case road     = 5  // local level => how do I navigate on the road?
    case city     = 10 // can fit a city => where in the city are we?
    case country  = 15 // can fit a country => where in the world/in this country are we?
  }
  
  var annotations = [MKAnnotation]() {
    didSet {
      guard let mapView = mapView else { return }
      mapView.removeAnnotations(oldValue)
      mapView.addAnnotations(annotations)
    }
  }
  
  /// Edge padding of the map view, e.g., if parts of the map view is
  /// obscured by other views, this should be set accordingly.
  var edgePadding: UIEdgeInsets = .zero
  
  /// How zoomed in/out the map should be when displaying the
  /// content the first time.
  var preferredZoomLevel: Zoom = .city
  
  fileprivate weak var mapView: MKMapView?
  
  fileprivate var isActive: Bool {
    return mapView != nil
  }
  
  /// Takes charge of the map view, adding the map manager's content
  ///
  /// - Parameters:
  ///   - mapView: Map view to take charge of
  ///   - animated: If adding content should be animated
  func takeCharge(of mapView: MKMapView, animated: Bool = true) {
    self.mapView = mapView
    mapView.addAnnotations(annotations)
    
    mapView.showAnnotations(annotations, animated: false)
    mapView.setZoomLevel(preferredZoomLevel.rawValue, edgePadding: edgePadding, animated: animated)
  }
  
  /// Cleanes up the map view, removing the map manager's content
  /// and restoring the map view to a state similar to when 
  /// `takeCharge(of:)` was called.
  ///
  /// - Parameters:
  ///   - mapView: Map view to clean-up
  ///   - animated: If removing content should be animated
  func cleanUp(_ mapView: MKMapView, animated: Bool = true) {
    guard mapView == self.mapView else {
      assertionFailure("Not the map view that we manage!")
      return
    }
    
    mapView.removeAnnotations(annotations)
    self.mapView = nil
  }
  
}

extension MKMapView {
  
  var zoomLevel: Double {
    get {
      return zoomLevel(of: visibleMapRect)
    }
    set {
      setZoomLevel(newValue, animated: false)
    }
  }
  
  func setZoomLevel(_ zoomLevel: Double, edgePadding: UIEdgeInsets = .zero, animated: Bool) {
    let mapRect = self.mapRect(forZoomLevel: zoomLevel)
    setVisibleMapRect(mapRect, edgePadding: edgePadding, animated: animated)
  }
  
  fileprivate func zoomLevel(of mapRect: MKMapRect) -> Double {
    return log(mapRect.size.width / Double(frame.height)) / log(2) + 1
  }
  
  fileprivate func mapRect(forZoomLevel zoomLevel: Double) -> MKMapRect {
    let center = MKMapPointForCoordinate(centerCoordinate)
    
    let ratio = pow(2, zoomLevel - 1)
    
    let viewRatio = Double(frame.width / frame.height)
    let width = Double(frame.height) * ratio
    let height = width / viewRatio
    
    return MKMapRect(origin: MKMapPoint(x: center.x - width / 2, y: center.y - height / 2), size: MKMapSize(width: width, height: height))
  }
  
}

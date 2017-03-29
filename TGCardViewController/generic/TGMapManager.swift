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
  
  /// How zoomed in/out the map should be when displaying the
  /// content the first time.
  var preferredZoomLevel: Zoom = .city
  
  fileprivate var edgePadding: UIEdgeInsets = .zero
  
  fileprivate weak var mapView: MKMapView?
  
  fileprivate var isActive: Bool {
    return mapView != nil
  }
  
  /// Takes charge of the map view, adding the map manager's content
  ///
  /// - Parameters:
  ///   - mapView: Map view to take charge of
  ///   - edgePadding: Edge padding of the map view, e.g., if parts of the map view is
  /// obscured by other views.
  ///   - animated: If adding content should be animated
  func takeCharge(of mapView: MKMapView, edgePadding: UIEdgeInsets = .zero, animated: Bool = true) {
    self.mapView = mapView
    self.edgePadding = edgePadding
    
    mapView.addAnnotations(annotations)
    
    mapView.showAnnotations(annotations,
                            minimumZoomLevel: preferredZoomLevel.rawValue,
                            edgePadding: edgePadding,
                            animated: animated)
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
  
  func showAnnotations(_ annotations: [MKAnnotation], minimumZoomLevel: Double, edgePadding: UIEdgeInsets = .zero, animated: Bool) {
    
    // Note: Using zero insets here as we'll respect the inspect already in the
    //       call below when setting the visible map rect - otherwise we adjust
    //       for it twice.
    var mapRect = mapRectThatFits(annotations.boundingMapRect, edgePadding: .zero)
    
    if zoomLevel(of: mapRect) < minimumZoomLevel {
      let center = MKMapPoint(x: MKMapRectGetMidX(mapRect), y: MKMapRectGetMidY(mapRect))
      mapRect = self.mapRect(forZoomLevel: minimumZoomLevel, centeredOn: center)
    }
    
    setVisibleMapRect(mapRect, edgePadding: edgePadding, animated: animated)
  }
  
}

extension Array where Element == MKAnnotation {
  
  var boundingMapRect: MKMapRect {
    return reduce(MKMapRectNull) { acc, annotation in
      let point = MKMapPointForCoordinate(annotation.coordinate)
      let miniRect = MKMapRect(origin: point, size: MKMapSize(width: 1, height: 1))
      return MKMapRectUnion(acc, miniRect)
    }
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
    let center = MKMapPointForCoordinate(centerCoordinate)
    let mapRect = self.mapRect(forZoomLevel: zoomLevel, centeredOn: center)
    setVisibleMapRect(mapRect, edgePadding: edgePadding, animated: animated)
  }
  
  fileprivate func zoomLevel(of mapRect: MKMapRect) -> Double {
    return log(mapRect.size.width / Double(frame.height)) / log(2) + 1
  }
  
  fileprivate func mapRect(forZoomLevel zoomLevel: Double, centeredOn center: MKMapPoint) -> MKMapRect {
    
    let ratio = pow(2, zoomLevel - 1)
    
    let viewRatio = Double(frame.width / frame.height)
    let width = Double(frame.height) * ratio
    let height = width / viewRatio
    
    return MKMapRect(origin: MKMapPoint(x: center.x - width / 2, y: center.y - height / 2), size: MKMapSize(width: width, height: height))
  }
  
}

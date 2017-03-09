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
  
  var annotations = [MKAnnotation]() {
    didSet {
      guard let mapView = mapView else { return }
      mapView.removeAnnotations(oldValue)
      mapView.addAnnotations(annotations)
    }
  }
  
  fileprivate weak var mapView: MKMapView?
  
  fileprivate var isActive: Bool {
    return mapView != nil
  }
  
  func takeCharge(of mapView: MKMapView) {
    self.mapView = mapView
    mapView.addAnnotations(annotations)
  }
  
  func cleanUp(_ mapView: MKMapView) {
    guard mapView == self.mapView else {
      assertionFailure("Not the map view that we manage!")
      return
    }
    
    mapView.removeAnnotations(annotations)
    self.mapView = nil
  }
  
}

//
//  Helpers.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 26/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import MapKit

extension TGMapManager {
  
  @nonobjc static var nuremberg  = TGMapManager(lat:  49.45, lng:  11.08, level: .country)
  @nonobjc static var london     = TGMapManager(lat:  51.46, lng:  -0.09)
  @nonobjc static var sydney     = TGMapManager(lat: -33.86, lng: 151.21)
  
  fileprivate convenience init(lat: CLLocationDegrees, lng: CLLocationDegrees, level: Zoom = .city) {
    self.init()
    annotations = [MKPointAnnotation(lat: lat, lng: lng)]
    preferredZoomLevel = level
  }
}

extension MKPointAnnotation {
  
  convenience init(lat: CLLocationDegrees, lng: CLLocationDegrees) {
    self.init()
    self.coordinate = CLLocationCoordinate2DMake(lat, lng)
  }
  
}

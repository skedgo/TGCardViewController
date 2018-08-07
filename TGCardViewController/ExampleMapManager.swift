//
//  ExampleMapManager.swift
//  Example
//
//  Created by Adrian Schönig on 03.08.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

import TGCardViewController

class ExampleMapManager: TGMapManager, NSCoding {
  @objc(ExampleMapManager)
  class CodingAnnotation: NSObject, MKAnnotation, NSCoding {
    let title: String?
    let subtitle: String?
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    
    init(for annotation: MKAnnotation) {
      self.title = annotation.title ?? nil
      self.subtitle = annotation.subtitle ?? nil
      self.latitude = annotation.coordinate.latitude
      self.longitude = annotation.coordinate.longitude
    }
    
    var coordinate: CLLocationCoordinate2D {
      return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func encode(with aCoder: NSCoder) {
      aCoder.encode(title, forKey: "title")
      aCoder.encode(subtitle, forKey: "subtitle")
      aCoder.encode(latitude, forKey: "latitude")
      aCoder.encode(longitude, forKey: "longitude")
    }
    
    required init?(coder aDecoder: NSCoder) {
      title = aDecoder.decodeObject(forKey: "title") as? String
      subtitle = aDecoder.decodeObject(forKey: "subtitle") as? String
      latitude = aDecoder.decodeDouble(forKey: "latitude")
      longitude = aDecoder.decodeDouble(forKey: "longitude")
    }
  }
  
  override init() {
    super.init()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init()
    annotations = aDecoder.decodeObject(forKey: "annotations") as? [MKAnnotation] ?? []
  }
  
  func encode(with aCoder: NSCoder) {
    aCoder.encode(annotations.map(CodingAnnotation.init), forKey: "annotations")
  }
}

//
//  ExampleCityCard.swift
//  Example
//
//  Created by Adrian Schönig on 03.08.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

import TGCardViewController

@MainActor
class ExampleCityCard : TGPlainCard {
  
  enum City: String {
    case nuremberg
    case london
    case sydney
    
    var title: String {
      switch self {
      case .london: return "Good day London"
      case .nuremberg: return "Sers Nemberch"
      case .sydney: return "G'day Sydney"
      }
    }
    
    @MainActor
    var manager: TGMapManager {
      switch self {
      case .london: return .london
      case .nuremberg: return .nuremberg
      case .sydney: return .sydney
      }
    }
  }
  
  let city: City
   
  init(city: City) {
    self.city = city
    super.init(title: .default(city.title, nil, nil), mapManager: city.manager)
  }
  
  required init?(coder: NSCoder) {
    guard let rawCity = coder.decodeObject(forKey: "city") as? String, let city = City(rawValue: rawCity) else {
      return nil
    }
    self.city = city
    
    // Note that this restores the title, but not the map manager...
    super.init(coder: coder)
    
    // Map manager isn't restored automatically, so we do it manually.
    // Another option is to use a map manager that conforms to `NSCoding`.
    // See `ExampleMapManager` and its uses.
    self.mapManager = city.manager
  }
  
  override func encode(with aCoder: NSCoder) {
    super.encode(with: aCoder)
    aCoder.encode(city.rawValue, forKey: "city")
  }
  
}

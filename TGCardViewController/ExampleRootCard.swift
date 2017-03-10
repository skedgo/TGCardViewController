//
//  ExampleRootCard.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import MapKit

class ExampleRootCard : TGPlainCard {
  
  init() {
    let content = ExampleRootContentView.instantiate()
    
    let nuremberg = MKPointAnnotation()
    nuremberg.coordinate = CLLocationCoordinate2DMake(49.45, 11.08)
    
    let mapManager = TGMapManager()
    mapManager.annotations = [nuremberg]
    mapManager.preferredZoomLevel = .country
    
    super.init(title: "Root", contentView: content, mapManager: mapManager)

    content.addChildButton.addTarget(self, action: #selector(addChildTapped(sender:)), for: .touchUpInside)
  }
  
  @objc
  func addChildTapped(sender: Any) {
    let child = ExampleChildCard()
    controller?.push(child)
  }
  
}

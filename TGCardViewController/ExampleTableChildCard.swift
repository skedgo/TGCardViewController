//
//  ExampleTableChildCard.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 15/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import MapKit

class ExampleTableChildCard : TGPlainCard {
  
  init(annotation: MKAnnotation) {
    let label = UILabel()
    label.text = "Some more content about the location would go here. But we don't have anything here for this demo."
    label.numberOfLines = 0
    label.sizeToFit()
    
    let mapManager = TGMapManager()
    mapManager.annotations = [annotation]
    mapManager.preferredZoomLevel = .road
    
    let wrappedTitle = annotation.title ?? nil
    
    super.init(title: wrappedTitle ?? "No title", subtitle: annotation.subtitle ?? nil, contentView: label, mapManager: mapManager, position: .collapsed)
  }
}

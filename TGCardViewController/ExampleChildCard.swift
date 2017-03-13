//
//  ExampleChildCard.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import MapKit

class ExampleChildCard : TGPlainCard {
  
  init() {
    let content = ExampleChildContentView.instantiate()
    
    let sydney = MKPointAnnotation()
    sydney.coordinate = CLLocationCoordinate2DMake(-33.86, 151.21)
    
    let mapManager = TGMapManager()
    mapManager.annotations = [sydney]
    mapManager.preferredZoomLevel = .city
    
    super.init(title: "Child", subtitle: "With sticky button", contentView: content, mapManager: mapManager)
    
    content.showStickyButton.addTarget(self, action: #selector(showStickyTapped(sender:)), for: .touchUpInside)
  }
  
  fileprivate lazy var image = ExampleChildStickyView.instantiate()
  
  @objc
  func showStickyTapped(sender: Any) {
    guard let controller = controller else { return }
    
    if controller.isShowingSticky {
      controller.hideStickyBar(animated: true)
    } else {
      controller.showStickyBar(content: image, animated: true)
    }
  }
  
}

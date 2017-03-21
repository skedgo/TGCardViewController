//
//  ExampleScrollCard.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 20/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import MapKit

class ExampleScrollCard: TGScrollCard {
  
  init() {
    let card1 = TGPlainCard(title: "Sample card 1")
    
    let card2 = ExampleTableCard()
    
    let card3 = ExampleChildCard()
    
    let sydney = MKPointAnnotation()
    sydney.coordinate = CLLocationCoordinate2DMake(-33.86, 151.21)
    
    let mapManager = TGMapManager()
    mapManager.annotations = [sydney]
    mapManager.preferredZoomLevel = .city
    
    super.init(title: "Paging views", contentCards: [card1, card2, card3], mapManager: mapManager)
  }
  
  override func willAppear(animated: Bool) {
    super.willAppear(animated: animated)
    
    let stickyContent = ExampleScrollStickyView.instantiate()
    stickyContent.closeButton.addTarget(self, action: #selector(closeButtonTapped(sender:)), for: .touchUpInside)
    controller?.showStickyBar(content: stickyContent, animated: true)
  }
  
  @objc
  func closeButtonTapped(sender: Any) {
    controller?.pop()
    controller?.hideStickyBar(animated: true)
  }
  
}

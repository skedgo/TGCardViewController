//
//  MockupImageCard.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 16/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import UIKit
import MapKit

import TGCardViewController

class MockupImageCard : TGPlainCard {
  
  typealias Target = (range: Range<CGFloat>, card: TGCard)
  
  let targets: [Target]
  
  init(title: String, subtitle: String? = nil, image: UIImage, locations: [MKAnnotation] = [], targets: [Target] = []) {
    self.targets = targets
    
    let content = MockupImageContentView.instantiate()
    content.imageView.image = image
    
    let mapManager = locations.count > 0 ? TGMapManager() : nil
    mapManager?.annotations = locations
    mapManager?.preferredZoomLevel = .road
    
    super.init(title: .default(title, subtitle, nil), contentView: content, mapManager: mapManager)

    let tapper = UITapGestureRecognizer()
    tapper.addTarget(self, action: #selector(handleTap))
    content.addGestureRecognizer(tapper)
  }
  
  required convenience init?(coder: NSCoder) {
    return nil
  }
  
  override func buildCardView() -> TGCardView {
    guard
      let content = contentView as? MockupImageContentView,
      let image = content.imageView.image,
      let wrapper = controller?.cardWrapperContent
      else {
        preconditionFailure()
    }
    
    let ratio = image.size.height / image.size.width
    content.imageWidthConstraint.constant  = wrapper.bounds.width
    content.imageHeightConstraint.constant = wrapper.bounds.width * ratio
    
    return super.buildCardView()
  }
  
  @objc
  func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
    guard let view = gestureRecognizer.view else { return }
    let location = gestureRecognizer.location(in: view)
    
    for target in targets {
      let proportion = location.y / view.frame.height
      if target.range.contains(proportion) {
        controller?.push(target.card)
        return
      }
    }
  }
  
}

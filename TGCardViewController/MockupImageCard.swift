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
    
    super.init(title: title, subtitle: subtitle, contentView: content, mapManager: mapManager, position: .peaking)

    let tapper = UITapGestureRecognizer()
    tapper.addTarget(self, action: #selector(handleTap))
    content.addGestureRecognizer(tapper)
  }
  
  override func buildCardView(showClose: Bool, includeHeader: Bool) -> TGCardView {
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

    return super.buildCardView(showClose: showClose, includeHeader: includeHeader)
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
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
  
  init(title: String, subtitle: String? = nil, image: UIImage, targets: [Target] = []) {
    self.targets = targets
    
    let content = MockupImageContentView.instantiate()
    content.imageView.image = image
    
    let ratio = image.size.height / image.size.width
    content.imageWidthConstraint.constant  = UIScreen.main.bounds.width
    content.imageHeightConstraint.constant = UIScreen.main.bounds.width * ratio
    
    super.init(title: title, subtitle: subtitle, contentView: content, mapManager: nil, position: .peaking)

    let tapper = UITapGestureRecognizer()
    tapper.addTarget(self, action: #selector(handleTap))
    content.addGestureRecognizer(tapper)
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

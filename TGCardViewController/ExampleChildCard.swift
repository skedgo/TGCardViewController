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
    
    let accessoryLabel = UILabel()
    accessoryLabel.text = "This is an accessory view"
    accessoryLabel.textColor = .cyan
    accessoryLabel.textAlignment = .center
    accessoryLabel.sizeToFit()
    
    super.init(title: "Child", subtitle: "With sticky button", contentView: content, accessoryView: accessoryLabel, mapManager: .sydney)
    
    content.showStickyButton.addTarget(self, action: #selector(toggleStickyImagePressed(sender:)), for: .touchUpInside)
    content.showStickyCreditsButton.addTarget(self, action: #selector(toggleStickyCreditsPressed(sender:)), for: .touchUpInside)
  }
  

  fileprivate enum StickyMode {
    case image
    case credits
    case none
  }
  
  fileprivate var stickyMode: StickyMode = .none {
    didSet {
      switch stickyMode {
      case .credits: controller?.showStickyBar(content: stickyCredits, animated: true)
      case .image:   controller?.showStickyBar(content: stickyImage, animated: true)
      case .none:    controller?.hideStickyBar(animated: true)
      }
    }
  }
  
  fileprivate lazy var stickyCredits: UIView = {
    let label = UILabel()
    label.numberOfLines = 2
    label.text = "\nErlkönig - Göthe"
    label.sizeToFit()
    return label
  }()
  
  
  fileprivate lazy var stickyImage = ExampleChildStickyView.instantiate()
  
  @objc
  func toggleStickyImagePressed(sender: Any) {
    switch stickyMode {
    case .none, .credits: stickyMode = .image
    case .image:          stickyMode = .none
    }
  }
  
  
  @objc
  func toggleStickyCreditsPressed(sender: Any) {
    switch stickyMode {
    case .none, .image: stickyMode = .credits
    case .credits:      stickyMode = .none
    }
  }
  
  
}

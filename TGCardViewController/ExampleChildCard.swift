//
//  ExampleChildCard.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import MapKit

import TGCardViewController

class ExampleChildCard : TGPlainCard {
  
  init() {
    let content = ExampleChildContentView.instantiate()
    
    let accessoryLabel = UILabel()
    accessoryLabel.text = "This is an accessory view"
    accessoryLabel.textColor = .cyan
    accessoryLabel.textAlignment = .center
    accessoryLabel.sizeToFit()
    
    super.init(title: "Child", subtitle: "With sticky button", contentView: content, accessoryView: accessoryLabel, mapManager: .sydney)
  }
  

  fileprivate enum StickyMode {
    case image
    case credits
    case none
  }
  
  fileprivate lazy var stickyCredits: UIView = {
    let label = UILabel()
    label.numberOfLines = 2
    label.text = "\nErlkönig - Göthe"
    label.sizeToFit()
    return label
  }()
  
}

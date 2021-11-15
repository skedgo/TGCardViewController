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
    
    super.init(title: .default("Child", "With sticky button", accessoryLabel), contentView: content, mapManager: TGMapManager.sydney)
    
    self.topMapToolBarItems = [UIButton.dummyDetailDisclosureButton(), UIButton.dummyDetailDisclosureButton()]
    self.bottomMapToolBarItems = [] // This forces an empty bottom floating view
  }
  
}

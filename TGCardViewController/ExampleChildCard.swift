//
//  ExampleChildCard.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class ExampleChildCard : TGPlainCard {
  
  init() {
    let content = ExampleChildContentView.instantiate()
    
    super.init(title: "Child", subtitle: "With sticky button", contentView: content)
    
    content.showStickyButton.addTarget(self, action: #selector(showStickyTapped(sender:)), for: .touchUpInside)
  }
  
  @objc
  func showStickyTapped(sender: Any) {
    guard let controller = controller else { return }
    
    if controller.isShowingSticky {
      controller.hideStickyBar(animated: true)
    } else {
      controller.showStickyBar(animated: true)
    }
  }
  
}

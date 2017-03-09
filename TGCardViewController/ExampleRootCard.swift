//
//  ExampleRootCard.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class ExampleRootCard : TGPlainCard {
  
  init() {
    let content = ExampleRootContentView.instantiate()
    
    super.init(title: "Root", contentView: content)

    content.addChildButton.addTarget(self, action: #selector(addChildTapped(sender:)), for: .touchUpInside)
  }
  
  @objc
  func addChildTapped(sender: Any) {
    let child = ExampleChildCard()
    controller?.push(child)
  }
  
}

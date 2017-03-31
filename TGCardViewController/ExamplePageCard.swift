//
//  ExamplePageCard.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 20/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import MapKit

class ExamplePageCard: TGPageCard {
  
  init() {
    let card1 = TGPlainCard(title: "Hello Sydney", mapManager: .sydney)
    let card2 = ExampleTableCard(mapManager: .london)
    let card3 = ExampleChildCard()
    let card4 = TGPlainCard(title: "Hello Nuremberg", mapManager: .nuremberg)
    super.init(title: "Paging views", cards: [card1, card2, card3, card4])
   
    // Custom accessory for testing jumping around
    let jumpButton = UIButton(type: .roundedRect)
    jumpButton.setTitle("Jump", for: .normal)
    jumpButton.addTarget(self, action: #selector(headerJumpPressed(sender:)), for: .touchUpInside)
    
    self.headerAccessoryView = jumpButton
  }
  
  @objc
  func headerJumpPressed(sender: Any) {
    let index = Int(arc4random_uniform(UInt32(self.cards.count)))
    move(to: index)
  }
  
}

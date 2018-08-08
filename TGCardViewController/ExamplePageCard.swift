//
//  ExamplePageCard.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 20/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import MapKit

import TGCardViewController

class ExamplePageCard: TGPageCard {
  
  init() {
    let card1 = ExampleCityCard(city: .sydney)
    let card2 = ExampleTableCard(pushOnTap: false)
    let card3 = ExampleChildCard()
    let card4 = ExampleCityCard(city: .nuremberg)
    super.init(cards: [card1, card2, card3, card4])
   
    // Custom accessory for testing jumping around
    let jumpButton = UIButton(type: .roundedRect)
    jumpButton.setTitle("Jump", for: .normal)
    jumpButton.addTarget(self, action: #selector(headerJumpPressed(sender:)), for: .touchUpInside)
    
    self.headerAccessoryView = jumpButton
    
    // This was added to debug toolbar issue when header was present
    self.topMapToolBarItems = [UIButton.dummySystemButton()]
  }
  
  required init?(coder: NSCoder) {
    // Note that this restores the child cards and the jump button.
    super.init(coder: coder)
  }
  
  @objc
  func headerJumpPressed(sender: Any) {
    let index = Int(arc4random_uniform(UInt32(self.cards.count)))
    move(to: index)
  }
  
}

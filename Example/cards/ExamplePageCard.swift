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
    var cards: [TGCard] = []
    cards.append(ExampleCityCard(city: .sydney))
    cards.append(ExampleTableCard(pushOnTap: false))
    if #available(iOS 16.0, *) {
      cards.append(ExampleChildCard())
    }
    cards.append(ExampleCityCard(city: .nuremberg))
    
    super.init(cards: cards)

    // Custom accessory for testing jumping around
    let jumpButton = UIButton(type: .roundedRect)
    jumpButton.setTitle("Jump", for: .normal)
    jumpButton.addTarget(self, action: #selector(headerJumpPressed(sender:)), for: .touchUpInside)
    
    self.headerAccessoryView = jumpButton
    
    // These were added to debug toolbar issue when header was present
    self.topMapToolBarItems = [UIButton.dummyDetailDisclosureButton()]
    self.bottomMapToolBarItems = [UIButton.dummyInfoLightButton()]
  }
  
  override func didBuild(cardView: TGCardView?, headerView: TGHeaderView?) {
    super.didBuild(cardView: cardView, headerView: headerView)
    
    headerView?.tintColor = .white
  }
  
  @objc
  func headerJumpPressed(sender: Any) {
    let index = (0..<cards.count)
      .filter { $0 != self.currentPageIndex }
      .randomElement()
      ?? 0
    move(to: index)
  }
  
}

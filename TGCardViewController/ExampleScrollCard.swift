//
//  ExampleScrollCard.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 20/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import MapKit

class ExampleScrollCard: TGScrollCard {
  
  init() {
    let mapManager = TGMapManager()
    let card1 = TGPlainCard(title: "Sample card 1", mapManager: mapManager)
    let card2 = ExampleTableCard()
    let card3 = ExampleChildCard()
    let card4 = TGPlainCard(title: "Sample card 4")
    let card5 = TGPlainCard(title: "Sample card 5")
    super.init(title: "Paging views", contentCards: [card1, card2, card3, card4, card5])
  }
  
  override func buildHeaderView() -> TGHeaderView? {
    let view = super.buildHeaderView()
    
    let jumpButton = UIButton(type: .roundedRect)
    jumpButton.setTitle("Jump", for: .normal)
    jumpButton.addTarget(self, action: #selector(headerJumpPressed(sender:)), for: .touchUpInside)
    view?.accessoryView = jumpButton
    
    return view
  }
  
  @objc
  func headerJumpPressed(sender: Any) {
    let index = Int(arc4random_uniform(UInt32(self.contentCards.count)))
    move(to: index)
  }
  
}

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
  
  override func willAppear(animated: Bool) {
    super.willAppear(animated: animated)
    showHeaderView()
  }
  
  override func willDisappear(animated: Bool) {
    super.willDisappear(animated: animated)
    controller?.hideStickyBar(animated: true)
  }
  
  fileprivate func showHeaderView() {
    let headerView = ExampleScrollStickyView.instantiate()
    
    headerView.nextButton.addTarget(self, action: #selector(headerNextPressed(sender:)), for: .touchUpInside)

    headerView.previousButton.addTarget(self, action: #selector(headerPreviousPressed(sender:)), for: .touchUpInside)

    headerView.jumpButton.addTarget(self, action: #selector(headerJumpPressed(sender:)), for: .touchUpInside)
    
    headerView.closeButton.addTarget(self, action: #selector(headerClosePressed(sender:)), for: .touchUpInside)
    
    
    controller?.showStickyBar(content: headerView, animated: true)
  }
  
  @objc
  func headerNextPressed(sender: Any) {
    moveForward()
  }

  @objc
  func headerPreviousPressed(sender: Any) {
    moveBackward()
  }
  
  @objc
  func headerJumpPressed(sender: Any) {
    let index = Int(arc4random_uniform(UInt32(self.contentCards.count)))
    move(to: index)
  }
  
  @objc
  func headerClosePressed(sender: Any) {
    controller?.pop()
  }
  
}

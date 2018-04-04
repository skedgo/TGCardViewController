//
//  ExampleTableCard.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 10/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TGCardViewController

class ExampleTableCard : TGTableCard {

  fileprivate let source = ExampleTableDataSource()

  init(mapManager: TGMapManager? = nil, pushOnTap: Bool = true) {
    let accessory = ExampleAccessoryView.instantiate()
    
    mapManager?.annotations = source.stops
    
    super.init(title: "London stops", dataSource: source, delegate: source, accessoryView: accessory, mapManager: mapManager)
    
    if pushOnTap {
      source.onSelect = {
        let card = ExampleTableChildCard(annotation: $0)
        self.controller?.push(card, animated: true)
      }
    } else {
      source.onSelect = {
        let annotation = $0
        self.mapManager?.setCenter(annotation.coordinate, animated: true)
      }
    }
    
    self.bottomFloatingViews = [UIButton.dummySystemButton()]
  }
  
  override func didBuild(cardView: TGCardView, headerView: TGHeaderView?) {
    super.didBuild(cardView: cardView, headerView: headerView)

    guard let tableView = (cardView as? TGTableCardView)?.tableView else { return }
    
    if #available(iOS 11.0, *) {
      tableView.dragInteractionEnabled = true
    }
  }
  
}

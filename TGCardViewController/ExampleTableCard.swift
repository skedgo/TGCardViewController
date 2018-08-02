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

  private let source = ExampleTableDataSource()
  private let pushOnTap: Bool

  init(mapManager: TGMapManager? = nil, pushOnTap: Bool = true) {
    
    self.pushOnTap = pushOnTap
    
    mapManager?.annotations = source.stops
    
    super.init(title: "London stops", dataSource: source, delegate: source, accessoryView: ExampleAccessoryView.instantiate(), mapManager: mapManager)
    
    if pushOnTap {
      source.onSelect = {
        let card = ExampleTableChildCard(annotation: $0)
        self.controller?.push(card, animated: true)
      }
    } else {
      source.onSelect = {
        let annotation = $0
        mapManager?.setCenter(annotation.coordinate, animated: true)
      }
    }
    
    self.bottomMapToolBarItems = [UIButton.dummySystemButton()]
  }
  
  required convenience init?(coder: NSCoder) {
    let mapManager = coder.decodeObject(forKey: "mapManager") as? TGMapManager
    let pushOnTap = coder.decodeBool(forKey: "pushOnTap")
    self.init(mapManager: mapManager, pushOnTap: pushOnTap)
  }
  
  override func encode(with aCoder: NSCoder) {
    aCoder.encode(mapManager, forKey: "mapManager")
    aCoder.encode(pushOnTap, forKey: "pushOnTap")
  }
  
  override func didBuild(cardView: TGCardView, headerView: TGHeaderView?) {
    super.didBuild(cardView: cardView, headerView: headerView)

    guard let tableView = (cardView as? TGScrollCardView)?.tableView else { return }
    
    if #available(iOS 11.0, *) {
      tableView.dragInteractionEnabled = true
    }
  }
  
}

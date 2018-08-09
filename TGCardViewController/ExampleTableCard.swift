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
  
  private var pushOnTap: Bool

  init(pushOnTap: Bool = true) {
    
    let mapManager = ExampleMapManager()
    mapManager.annotations = source.stops

    self.pushOnTap = pushOnTap

    super.init(title: "London stops", dataSource: source, delegate: source, accessoryView: ExampleAccessoryView.instantiate(), mapManager: mapManager)
    
    self.bottomMapToolBarItems = [UIButton.dummyDetailDisclosureButton()]
  }
  
  required init?(coder: NSCoder) {
    pushOnTap = coder.decodeBool(forKey: "pushOnTap")

    super.init(coder: coder)
    
    mapManager = coder.decodeObject(forKey: "mapManager") as? ExampleMapManager
    tableViewDataSource = source
    tableViewDelegate = source
  }
  
  override func encode(with aCoder: NSCoder) {
    super.encode(with: aCoder)
    
    assert(mapManager is ExampleMapManager)
    aCoder.encode(mapManager, forKey: "mapManager")
    
    aCoder.encode(pushOnTap, forKey: "pushOnTap")
  }
  
  override func didBuild(cardView: TGCardView, headerView: TGHeaderView?) {
    super.didBuild(cardView: cardView, headerView: headerView)

    guard let tableView = (cardView as? TGScrollCardView)?.tableView else { return }
    
    if #available(iOS 11.0, *) {
      tableView.dragInteractionEnabled = true
    }
    
    if pushOnTap {
      source.onSelect = {
        let card = ExampleTableChildCard(annotation: $0)
        self.controller?.push(card, animated: true)
      }
    } else {
      source.onSelect = {
        let annotation = $0
        (self.mapManager as? ExampleMapManager)?.setCenter(annotation.coordinate, animated: true)
      }
    }
  }
  
}

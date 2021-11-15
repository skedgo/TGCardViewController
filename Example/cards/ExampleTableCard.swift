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
    
    handleMacSelection = source.handleSelection
    bottomMapToolBarItems = [UIButton.dummyDetailDisclosureButton()]
  }
  
  override func didBuild(tableView: UITableView) {
    super.didBuild(tableView: tableView)

    tableView.dragInteractionEnabled = true
    
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

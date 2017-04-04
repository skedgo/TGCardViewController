//
//  ExampleTableCard.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 10/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class ExampleTableCard : TGTableCard {

  fileprivate let source = ExampleTableDataSource()

  init(mapManager: TGMapManager? = nil) {
    let accessory = ExampleAccessoryView.instantiate()
    
    super.init(title: "London stops", dataSource: source, delegate: source, accessoryView: accessory, mapManager: mapManager)
    
    source.onSelect = {
      let card = ExampleTableChildCard(annotation: $0)
      self.controller?.push(card, animated: true)
    }
  }
  
}

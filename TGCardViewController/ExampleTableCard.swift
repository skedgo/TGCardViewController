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
    let label = UILabel()
    label.textAlignment = .center
    label.text = "This is accessory view for table card"
    label.textColor = .orange
    label.sizeToFit()
    
    super.init(title: "London stops", dataSource: source, delegate: source, accessoryView: label, mapManager: mapManager)
    
    source.onSelect = {
      let card = ExampleTableChildCard(annotation: $0)
      self.controller?.push(card, animated: true)
    }
  }
  
}

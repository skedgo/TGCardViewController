//
//  ExampleAgendaCard.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 15/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class ExampleAgendaCard: TGAgendaCard {
  
  fileprivate let source = ExampleTableDataSource()
  
  init() {
    let container = UIView()
    let label = UILabel()
    label.text = "This is where weekly selector goes"
    label.center(on: container)
    super.init(title: "Agenda", dataSource: source, delegate: source, bottomContent: container)
  }
  
}

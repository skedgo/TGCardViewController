//
//  ExampleAgendaCard.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 15/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class ExampleAgendaCard: TGAgendaCard {
  
  fileprivate let source = ExampleDataSource()
  
  init() {
    super.init(title: "Agenda", dataSource: source, delegate: source)
  }
  
}

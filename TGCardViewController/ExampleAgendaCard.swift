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
  
  override func buildView(showClose: Bool) -> TGCardView {
    let view = TGAgendaCardView.newInstance()
    view.configure(with: self, showClose: showClose)
    return view
  }
  
}

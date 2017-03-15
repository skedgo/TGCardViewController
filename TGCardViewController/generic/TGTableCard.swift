//
//  TGTableCard.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 10/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TGTableCard : TGCard {
  
  weak var controller: TGCardViewController?
  
  let title: String
  let subtitle: String?
  let mapManager: TGMapManager?

  weak var tableViewDelegate: UITableViewDelegate?
  weak var tableViewDataSource: UITableViewDataSource?
  
  init(title: String, subtitle: String? = nil, dataSource: UITableViewDataSource, delegate: UITableViewDelegate? = nil, mapManager: TGMapManager? = nil) {
    
    self.title = title
    self.subtitle = subtitle
    self.mapManager = mapManager
    self.tableViewDataSource = dataSource
    self.tableViewDelegate = delegate
  }
  
  func buildView(showClose: Bool) -> TGCardView {
    let view = TGTableCardView.instantiate()
    view.configure(with: self, showClose: showClose)
    return view
  }
  
}

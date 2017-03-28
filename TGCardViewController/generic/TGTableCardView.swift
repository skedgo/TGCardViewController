//
//  TGTableCardView.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 10/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TGTableCardView: TGCardView {
  
  @IBOutlet weak var tableView: UITableView!
  
  static func instantiate() -> TGTableCardView {
    let bundle = Bundle(for: self)
    return bundle.loadNibNamed("TGTableCardView", owner: nil, options: nil)!.first as! TGTableCardView
  }
  
  func configure(with card: TGTableCard, showClose: Bool, includeHeader: Bool) {
    super.configure(with: card, showClose: showClose, includeHeader: includeHeader)
    
    tableView.dataSource = card.tableViewDataSource
    tableView.delegate = card.tableViewDelegate
  }
  
}

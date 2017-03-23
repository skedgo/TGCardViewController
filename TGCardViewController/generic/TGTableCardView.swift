//
//  TGTableCardView.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 10/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TGTableCardView: TGCardView {

  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subtitleLabel: UILabel!
  
  @IBOutlet weak var tableView: UITableView!
  
  static func instantiate() -> TGTableCardView {
    let bundle = Bundle(for: self)
    return bundle.loadNibNamed("TGTableCardView", owner: nil, options: nil)!.first as! TGTableCardView
  }
  
  func configure(with card: TGTableCard, showClose: Bool) {
    titleLabel.text = card.title
    subtitleLabel.text = card.subtitle    
    closeButton?.isHidden = !showClose
    
    tableView.dataSource = card.tableViewDataSource
    tableView.delegate = card.tableViewDelegate
  }
  
}

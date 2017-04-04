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
  

  override func awakeFromNib() {
    super.awakeFromNib()
    
    closeButton?.setImage(TGCardStyleKit.imageOfCardCloseIcon, for: .normal)
    closeButton?.setTitle(nil, for: .normal)
    closeButton?.accessibilityLabel = NSLocalizedString("Close", comment: "Close button accessory title")
  }
  
  
  func configure(with card: TGTableCard, showClose: Bool, includeHeader: Bool) {
    super.configure(with: card, showClose: showClose, includeHeader: includeHeader)
    
    if includeHeader {
      accessoryView = card.accessoryView
    }
    
    tableView.dataSource = card.tableViewDataSource
    tableView.delegate = card.tableViewDelegate
  }
  
}

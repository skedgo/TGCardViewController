//
//  TGTableCardView.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 10/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

public class TGTableCardView: TGCardView {
  
  public weak var tableView: UITableView!
  
  // This is where the table view is going to be. We didn't insert
  // table view directly because the style of table view is only
  // known at run time. Using a wrapper helps us fix the constraints
  // at design time.
  @IBOutlet weak var tableWrapper: UIView!
  
  // MARK: - New instances
  
  static func instantiate() -> TGTableCardView {
    let bundle = Bundle(for: self)
    guard
      let view = bundle.loadNibNamed("TGTableCardView", owner: nil, options: nil)!.first as? TGTableCardView
      else { preconditionFailure() }
    return view
  }

  override public func awakeFromNib() {
    super.awakeFromNib()
    
    closeButton?.setImage(TGCardStyleKit.imageOfCardCloseIcon, for: .normal)
    closeButton?.setTitle(nil, for: .normal)
    closeButton?.accessibilityLabel = NSLocalizedString("Close", comment: "Close button accessory title")
  }
  
  // MARK: - Configuration
  
  override func configure(with card: TGCard, showClose: Bool, includeHeader: Bool) {
    guard let card = card as? TGTableCard else {
      preconditionFailure()
    }
    
    super.configure(with: card, showClose: showClose, includeHeader: includeHeader)
    
    if includeHeader {
      accessoryView = card.accessoryView
    }
    
    let tableView = UITableView(frame: .zero, style: card.tableStyle)
    tableView.dataSource = card.tableViewDataSource
    tableView.delegate = card.tableViewDelegate
    
    tableWrapper.addSubview(tableView)
    tableView.snap(to: tableWrapper)
    
    self.tableView = tableView
    contentScrollView = tableView
  }
  
}

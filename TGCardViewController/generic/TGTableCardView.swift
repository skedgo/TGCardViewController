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
  
  // MARK: - Creating New View
  
  static func instantiate() -> TGTableCardView {
    let bundle = Bundle(for: self)
    guard
      let view = bundle.loadNibNamed("TGTableCardView", owner: nil, options: nil)!.first as? TGTableCardView
      else { preconditionFailure() }
    return view
  }
  
  // MARK: - Configuration
  
  override func titleAccessoryView(for card: TGCard) -> UIView? {
    guard let tableCard = card as? TGTableCard else { return nil }
    return tableCard.accessoryView
  }
  
  override func configure(with card: TGCard, includeTitleView: Bool, whenDismiss: ((Any) -> Void)?) {
    guard let tableCard = card as? TGTableCard else {
      preconditionFailure()
    }
    
    super.configure(with: tableCard, includeTitleView: includeTitleView, whenDismiss: whenDismiss)
        
    let tableView = UITableView(frame: .zero, style: tableCard.tableStyle)
    tableView.dataSource = tableCard.tableViewDataSource
    tableView.delegate = tableCard.tableViewDelegate
    
    if #available(iOS 11.0, *) {
      // For convenience, we also assign the delegate for dragging
      // and dropping directly if possible.
      tableView.dragDelegate = tableCard.tableViewDelegate as? UITableViewDragDelegate
      tableView.dropDelegate = tableCard.tableViewDelegate as? UITableViewDropDelegate
    }
    
    tableWrapper.addSubview(tableView)
    tableView.snap(to: tableWrapper)
    
    self.tableView = tableView
    contentScrollView = tableView
  }
  
}

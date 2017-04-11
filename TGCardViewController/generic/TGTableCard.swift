//
//  TGTableCard.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 10/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

open class TGTableCard: TGCard {
  
  public let tableStyle: UITableViewStyle
  
  let accessoryView: UIView?

  weak var tableViewDelegate: UITableViewDelegate?
  weak var tableViewDataSource: UITableViewDataSource?
  
  public init(title: String, subtitle: String? = nil,
              dataSource: UITableViewDataSource? = nil,
              delegate: UITableViewDelegate? = nil,
              style: UITableViewStyle = .plain,
              accessoryView: UIView? = nil,
              mapManager: TGMapManager? = nil) {
    
    self.tableViewDataSource = dataSource
    self.tableViewDelegate = delegate
    self.tableStyle = style
    self.accessoryView = accessoryView
    
    super.init(title: title, subtitle: subtitle,
               mapManager: mapManager, position: mapManager != nil ? .peaking : .extended)
  }
  
  public override func buildCardView(showClose: Bool, includeHeader: Bool) -> TGCardView {
    let view = TGTableCardView.instantiate()
    view.configure(with: self, showClose: showClose, includeHeader: includeHeader)
    return view
  }
 
}

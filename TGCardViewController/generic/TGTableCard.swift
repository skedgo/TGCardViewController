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
  
  weak var delegate: TGCardDelegate? = nil
  
  let title: String
  let subtitle: String?
  let mapManager: TGMapManager?
  let defaultPosition: TGCardPosition
  
  let accessoryView: UIView?

  weak var tableViewDelegate: UITableViewDelegate?
  weak var tableViewDataSource: UITableViewDataSource?
  
  init(title: String, subtitle: String? = nil, dataSource: UITableViewDataSource, delegate: UITableViewDelegate? = nil, accessoryView: UIView? = nil, mapManager: TGMapManager? = nil) {
    
    self.title = title
    self.subtitle = subtitle
    self.mapManager = mapManager
    self.tableViewDataSource = dataSource
    self.tableViewDelegate = delegate
    self.accessoryView = accessoryView
    self.defaultPosition = mapManager != nil ? .peaking : .extended
  }
  
  func buildCardView(showClose: Bool, includeHeader: Bool) -> TGCardView {
    let view = TGTableCardView.instantiate()
    view.configure(with: self, showClose: showClose, includeHeader: includeHeader)
    return view
  }
 
  func buildHeaderView() -> TGHeaderView? {
    return nil
  }

  func willAppear(animated: Bool) {
//    print("+. \(title) will appear")
  }
  
  func didAppear(animated: Bool) {
//    print("++ \(title) did appear")
  }
  
  func willDisappear(animated: Bool) {
//    print("-. \(title) will disappear")
  }
  
  func didDisappear(animated: Bool) {
//    print("-- \(title) did disappear")
  }

}

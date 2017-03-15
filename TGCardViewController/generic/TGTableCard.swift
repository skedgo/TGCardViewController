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
  let bottomView: UIView?

  weak var tableViewDelegate: UITableViewDelegate?
  weak var tableViewDataSource: UITableViewDataSource?
  
  init(title: String, subtitle: String? = nil, dataSource: UITableViewDataSource, delegate: UITableViewDelegate? = nil, bottomView: UIView? = nil, mapManager: TGMapManager? = nil) {
    
    self.title = title
    self.subtitle = subtitle
    self.mapManager = mapManager
    self.bottomView = bottomView
    self.tableViewDataSource = dataSource
    self.tableViewDelegate = delegate
  }
  
  func buildView(showClose: Bool) -> TGCardView {
    let view = TGTableCardView.instantiate()
    view.showBottomView(show: bottomView != nil)
    view.configure(with: self, showClose: showClose)
    return view
  }
  
  func willAppear(animated: Bool) { }
  
  func didAppear(animated: Bool) { }
  
  func willDisappear(animated: Bool) { }
  
  func didDisappear(animated: Bool) { }
  
}

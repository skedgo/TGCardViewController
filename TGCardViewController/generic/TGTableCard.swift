//
//  TGTableCard.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 10/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

public class TGTableCard : TGCard {
  
  public weak var controller: TGCardViewController?
  
  public weak var delegate: TGCardDelegate? = nil
  
  public let title: String
  public let subtitle: String?
  public let mapManager: TGMapManager?
  public let defaultPosition: TGCardPosition

  weak var tableViewDelegate: UITableViewDelegate?
  weak var tableViewDataSource: UITableViewDataSource?
  
  init(title: String, subtitle: String? = nil, dataSource: UITableViewDataSource, delegate: UITableViewDelegate? = nil, mapManager: TGMapManager? = nil) {
    
    self.title = title
    self.subtitle = subtitle
    self.mapManager = mapManager
    self.tableViewDataSource = dataSource
    self.tableViewDelegate = delegate
    self.defaultPosition = mapManager != nil ? .peaking : .extended
  }
  
  public func buildCardView(showClose: Bool, includeHeader: Bool) -> TGCardView {
    let view = TGTableCardView.instantiate()
    view.configure(with: self, showClose: showClose, includeHeader: includeHeader)
    return view
  }
 
  public func buildHeaderView() -> TGHeaderView? {
    return nil
  }

  public func willAppear(animated: Bool) {
//    print("+. \(title) will appear")
  }
  
  public func didAppear(animated: Bool) {
//    print("++ \(title) did appear")
  }
  
  public func willDisappear(animated: Bool) {
//    print("-. \(title) will disappear")
  }
  
  public func didDisappear(animated: Bool) {
//    print("-- \(title) did disappear")
  }

}

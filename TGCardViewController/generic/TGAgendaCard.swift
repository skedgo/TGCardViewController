//
//  TGAgendacard.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 16/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TGAgendaCard: TGCard {
  
  weak var controller: TGCardViewController?
  
  weak var delegate: TGCardDelegate? = nil
  
  let title: String
  let subtitle: String?
  let mapManager: TGMapManager?
  let defaultPosition: TGCardPosition = .peaking
  
  /// This is the content for the bottom view.
  let bottomContentView: UIView?
  
  /// These are used to configure the main content view.
  var tableViewDataSource: UITableViewDataSource?
  var tableViewDelegate: UITableViewDelegate?
  
  // MARK: - Initializers
  
  init(title: String, subtitle: String? = nil, mapManager: TGMapManager? = nil, dataSource: UITableViewDataSource? = nil, delegate: UITableViewDelegate?, bottomContent: UIView? = nil) {
    self.title = title
    self.subtitle = subtitle
    self.mapManager = mapManager
    self.bottomContentView = bottomContent
    self.tableViewDelegate = delegate
    self.tableViewDataSource = dataSource
  }
  
  // MARK: - Constructing views.
  
  func buildCardView(showClose: Bool, includeHeader: Bool) -> TGCardView {
    let view = TGAgendaCardView.instantiate()
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

//
//  TGAgendacard.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 16/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

open class TGAgendaCard: TGCard {
  
  /// This is the content for the bottom view.
  let bottomContentView: UIView?
  
  /// These are used to configure the main content view.
  weak var tableViewDataSource: UITableViewDataSource?
  weak var tableViewDelegate: UITableViewDelegate?
  
  // MARK: - Initializers
  
  public init(title: String, subtitle: String? = nil,
              dataSource: UITableViewDataSource? = nil,
              delegate: UITableViewDelegate? = nil,
              bottomContent: UIView? = nil,
              mapManager: TGMapManager? = nil) {
    self.bottomContentView = bottomContent
    self.tableViewDelegate = delegate
    self.tableViewDataSource = dataSource
    super.init(title: title, subtitle: subtitle, mapManager: mapManager)
  }
  
  // MARK: - Constructing views.
  
  public override func buildCardView(showClose: Bool, includeHeader: Bool) -> TGCardView {
    let view = TGAgendaCardView.instantiate()
    view.configure(with: self, showClose: showClose, includeHeader: includeHeader)
    return view
  }
    
}

//
//  TGAgendacard.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 16/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

open class TGAgendaCard: TGTableCard {
  
  /// This is the content for the bottom view.
  let bottomContentView: UIView?
  
  // MARK: - Initializers
  
  public init(title: String, subtitle: String? = nil,
              dataSource: UITableViewDataSource? = nil,
              delegate: UITableViewDelegate? = nil,
              bottomContent: UIView? = nil,
              mapManager: TGMapManager? = nil,
              initialPosition: TGCardPosition? = nil) {
    self.bottomContentView = bottomContent
    super.init(title: title, subtitle: subtitle,
               dataSource: dataSource, delegate: delegate,
               style: .plain, accessoryView: nil,
               mapManager: mapManager, initialPosition: initialPosition)
  }
  
  // MARK: - Constructing views.
  
  override public func buildCardView(showClose: Bool, includeHeader: Bool) -> TGCardView {
    let view = TGAgendaCardView.instantiate()
    view.configure(with: self, showClose: showClose, includeHeader: includeHeader)
    return view
  }
  
}

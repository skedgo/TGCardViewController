//
//  TGAgendacard.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 16/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

open class TGAgendaCard: TGCard {
  
  weak public var controller: TGCardViewController?
  
  weak public var delegate: TGCardDelegate? = nil
  
  public let title: String
  public let subtitle: String?
  public let mapManager: TGMapManager?
  public let defaultPosition: TGCardPosition = .peaking
  
  /// This is the content for the bottom view.
  let bottomContentView: UIView?
  
  /// These are used to configure the main content view.
  var tableViewDataSource: UITableViewDataSource?
  var tableViewDelegate: UITableViewDelegate?
  
  // MARK: - Initializers
  
  public init(title: String, subtitle: String? = nil, mapManager: TGMapManager? = nil, dataSource: UITableViewDataSource? = nil, delegate: UITableViewDelegate?, bottomContent: UIView? = nil) {
    self.title = title
    self.subtitle = subtitle
    self.mapManager = mapManager
    self.bottomContentView = bottomContent
    self.tableViewDelegate = delegate
    self.tableViewDataSource = dataSource
  }
  
  // MARK: - Constructing views.
  
  public func buildCardView(showClose: Bool, includeHeader: Bool) -> TGCardView {
    let view = TGAgendaCardView.instantiate()
    view.configure(with: self, showClose: showClose, includeHeader: includeHeader)
    return view
  }
  
  public func buildHeaderView() -> TGHeaderView? {
    return nil
  }
  
  open func willAppear(animated: Bool) {
//    print("+. \(title) will appear")
  }
  
  open func didAppear(animated: Bool) {
//    print("++ \(title) did appear")
  }
  
  open func willDisappear(animated: Bool) {
//    print("-. \(title) will disappear")
  }
  
  open func didDisappear(animated: Bool) {
//    print("-- \(title) did disappear")
  }
  
}

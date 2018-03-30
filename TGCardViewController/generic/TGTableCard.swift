//
//  TGTableCard.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 10/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

/// A table card is used for when you need a `UITableView`
/// as the card's content.
///
/// This class is generally subclassed.
open class TGTableCard: TGCard {
  
  public let tableStyle: UITableViewStyle
  
  let accessoryView: UIView?

  /// The delegate to be used for the card view's table view.
  ///
  /// Only has an effect, if it is set before `buildCardView` is called, i.e.,
  /// before the card is pushed.
  public weak var tableViewDelegate: UITableViewDelegate?
  
  /// The data source to be used for the card view's table view.
  ///
  /// Only has an effect, if it is set before `buildCardView` is called, i.e.,
  /// before the card is pushed.
  public weak var tableViewDataSource: UITableViewDataSource?
  
  // MARK: - Initialisers
  
  public init(title: String, subtitle: String? = nil,
              dataSource: UITableViewDataSource? = nil,
              delegate: UITableViewDelegate? = nil,
              style: UITableViewStyle = .plain,
              accessoryView: UIView? = nil,
              mapManager: TGMapManager? = nil,
              initialPosition: TGCardPosition? = nil) {
    
    self.tableViewDataSource = dataSource
    self.tableViewDelegate = delegate
    self.tableStyle = style
    self.accessoryView = accessoryView
    
    super.init(title: title, subtitle: subtitle,
               mapManager: mapManager, initialPosition: mapManager != nil ? initialPosition : .extended)
  }
  
  // MARK: - Constructing views
  
  open override func buildCardView(showClose: Bool, includeHeader: Bool) -> TGCardView {
    let view = TGTableCardView.instantiate()
    view.configure(with: self, showClose: showClose, includeHeader: includeHeader)
    return view
  }
 
}

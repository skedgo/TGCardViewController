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
  
  var cardView: TGCardView?
  let accessoryView: UIView?

  weak var tableViewDelegate: UITableViewDelegate?
  weak var tableViewDataSource: UITableViewDataSource?
  
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
  
  public override func buildCardView(showClose: Bool, includeHeader: Bool) -> TGCardView {
    let view = TGTableCardView.instantiate()
    view.configure(with: self, showClose: showClose, includeHeader: includeHeader)
    
    // We are overriding the table view (a.k.a scroll view)'s
    // delegate here because card needs to inform its view if
    // the content separator should be hidden.
    view.tableView.delegate = self
    
    // Keep a reference to the card view because we may adjust
    // its appearance at some later point.
    cardView = view
    
    return view
  }
 
}

// MARK: - Extensions

extension TGTableCard: UITableViewDelegate {
  
  fileprivate func scrollViewDidChangeContentOffset(_ scrollView: UIScrollView) {
    switch scrollView.contentOffset.y {
    case -1 * CGFloat.infinity ... 0:
      cardView?.contentSeparator?.isHidden = true
    default:
      cardView?.contentSeparator?.isHidden = false
    }
  }
  
  // MARK: - Table view delegate methods
  
  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    self.scrollViewDidChangeContentOffset(scrollView)
    tableViewDelegate?.scrollViewDidScroll?(scrollView)
  }
  
  public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    self.scrollViewDidChangeContentOffset(scrollView)
    tableViewDelegate?.scrollViewDidEndDecelerating?(scrollView)
  }
  
  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableViewDelegate?.tableView?(tableView, didSelectRowAt: indexPath)
  }
  
}

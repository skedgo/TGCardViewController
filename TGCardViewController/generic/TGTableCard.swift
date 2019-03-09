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
///
/// - warning: `TGTaleCard` supports state restoration, but will not
///     restore data sources and delegates. Override `init(coder:)` and
///     `encode(with:)` in your, making sure to call `super`.
open class TGTableCard: TGCard {
  
  public let tableStyle: UITableView.Style
  
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
  
  /// Whether the card should deselect the selected row when it appears.
  /// Defaults to `true`
  public var deselectOnAppear: Bool = true
  
  // MARK: - Initialisers
  
  public init(title: CardTitle,
              dataSource: UITableViewDataSource? = nil,
              delegate: UITableViewDelegate? = nil,
              style: UITableView.Style = .plain,
              mapManager: TGCompatibleMapManager? = nil,
              initialPosition: TGCardPosition? = nil) {
    
    self.tableViewDataSource = dataSource
    self.tableViewDelegate = delegate
    self.tableStyle = style
    
    super.init(title: title,
               mapManager: mapManager, initialPosition: mapManager != nil ? initialPosition : .extended)
  }
  
  public init(title: String,
              subtitle: String? = nil,
              dataSource: UITableViewDataSource? = nil,
              delegate: UITableViewDelegate? = nil,
              style: UITableView.Style = .plain,
              accessoryView: UIView? = nil,
              mapManager: TGCompatibleMapManager? = nil,
              initialPosition: TGCardPosition? = nil) {
    self.tableViewDataSource = dataSource
    self.tableViewDelegate = delegate
    self.tableStyle = style
    
    super.init(title: .default(title, subtitle, accessoryView),
               mapManager: mapManager, initialPosition: mapManager != nil ? initialPosition : .extended)
  }
  
  public required init?(coder: NSCoder) {
    self.tableStyle = UITableView.Style(rawValue: coder.decodeInteger(forKey: "tableStyle")) ?? .plain
    super.init(coder: coder)
  }
  
  open override func encode(with aCoder: NSCoder) {
    super.encode(with: aCoder)
    aCoder.encode(tableStyle.rawValue, forKey: "tableStyle")
  }
  // MARK: - Card Life Cycle
  
  open override func didAppear(animated: Bool) {
    super.didAppear(animated: animated)
    
    guard
      let scrollCardView = cardView as? TGScrollCardView,
      let embeddedScrollView = scrollCardView.embeddedScrollView
      else {
        assertionFailure()
        return
    }
    
    if #available(iOS 11, *) {
      embeddedScrollView.contentInset.bottom = scrollCardView.safeAreaInsets.bottom
      embeddedScrollView.scrollIndicatorInsets.bottom = scrollCardView.safeAreaInsets.bottom
    } else if let controller = controller {
      embeddedScrollView.contentInset.bottom = controller.bottomLayoutGuide.length
      embeddedScrollView.scrollIndicatorInsets.bottom = controller.bottomLayoutGuide.length
    }
    
    if deselectOnAppear, let tableView = scrollCardView.tableView, let selected = tableView.indexPathForSelectedRow {
      tableView.deselectRow(at: selected, animated: true)
    }
  }
  
  // MARK: - Constructing views
  
  open override func buildCardView(includeTitleView: Bool) -> TGCardView {
    let view = TGScrollCardView.instantiate()
    view.configure(with: self, includeTitleView: includeTitleView)
    return view
  }
 
}

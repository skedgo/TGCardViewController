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
/// - warning: `TGTableCard` does *not* support state restoration out of the
///     box. To support this, override `init(coder:)` in your subclass as a
///     convenience initialiser and implement it yourself. You can also
///     override `encode(with:)` - no need to call super for that.
open class TGTableCard: TGCard {
  
  public let tableStyle: UITableViewStyle
  
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
  
  public init(title: CardTitle,
              dataSource: UITableViewDataSource? = nil,
              delegate: UITableViewDelegate? = nil,
              style: UITableViewStyle = .plain,
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
              style: UITableViewStyle = .plain,
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
    return nil
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
  }
  
  // MARK: - Constructing views
  
  open override func buildCardView(includeTitleView: Bool) -> TGCardView {
    let view = TGScrollCardView.instantiate()
    view.configure(with: self, includeTitleView: includeTitleView)
    return view
  }
 
}

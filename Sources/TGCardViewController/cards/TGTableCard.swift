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
/// - warning: `TGTableCard` supports state restoration, but will not
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
  /// Defaults to `true` on iOS and `false` on macOS (Catalyst)
  public var deselectOnAppear: Bool = {
    #if targetEnvironment(macCatalyst)
    return false
    #else
    return true
    #endif
  }()
  
  /// Callback that is called when using this on Mac Catalyst, when the user select a cell via pressing enter
  /// on the keyboard during navigation, or when clicking an item in the list.
  ///
  /// - warning: Use this rather than the `UITableViewDelegate` selection method as that's called
  ///    while the user is still navigating via keyboard.
  ///
  /// - warning: Set this before returning from your `didBuild` override.
  public var handleMacSelection: (IndexPath) -> Void = { _ in }
  
  /// Special setting for Mac
  ///
  /// - warning: Set this before returning from your `didBuild` override.
  public var clickToHighlightDoubleClickToSelect: Bool = false
  
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
  
  /// Called when the views have been built the first time
  ///
  /// Think of this as an equivalent of `UIViewController.viewDidLoad`
  ///
  /// - note: You probably only want to override one of the `didBuild`, but both will be called.
  ///         Whichever you implement, remember to call `super`.
  ///
  /// - Parameters:
  ///   - tableView: The card's table view
  open func didBuild(tableView: UITableView) {
  }

  /// Called when the views have been built the first time
  ///
  /// Think of this as an equivalent of `UIViewController.viewDidLoad`
  ///
  /// - note: You probably only want to override one of the `didBuild`, but both will be called.
  ///         Whichever you implement, remember to call `super`.
  ///
  /// - Parameters:
  ///   - tableView: The card's table view
  ///   - cardView: The card view that got built
  open func didBuild(tableView: UITableView, cardView: TGCardView) {
  }

  override public final func didBuild(cardView: TGCardView?, headerView: TGHeaderView?) {
    
    defer { super.didBuild(cardView: cardView, headerView: headerView) }
    
    guard
      let cardView = cardView,
      let tableView = (cardView as? TGScrollCardView)?.tableView
      else { preconditionFailure() }

    didBuild(tableView: tableView, cardView: cardView)
    didBuild(tableView: tableView)

    if let keyboardTable = tableView as? TGKeyboardTableView {
      keyboardTable.handleMacSelection = handleMacSelection
      keyboardTable.clickToHighlightDoubleClickToSelect = clickToHighlightDoubleClickToSelect
    }
  }

  open override func didAppear(animated: Bool) {
    super.didAppear(animated: animated)
    
    guard
      let scrollCardView = cardView as? TGScrollCardView,
      let embeddedScrollView = scrollCardView.embeddedScrollView
      else {
        assertionFailure()
        return
    }
    
    var adjustment: CGFloat = 0
    if let header = controller?.headerView {
      adjustment = header.frame.maxY
    }
    
    if scrollCardView.safeAreaInsets.bottom > 0 {
      adjustment -= scrollCardView.safeAreaInsets.bottom
    }
    
    embeddedScrollView.contentInset.bottom = scrollCardView.safeAreaInsets.bottom + adjustment
    embeddedScrollView.verticalScrollIndicatorInsets.bottom = scrollCardView.safeAreaInsets.bottom + adjustment
    
    autoDeselect(scrollCardView)
  }
  
  private func autoDeselect(_ scrollCardView: TGScrollCardView) {
    guard
      deselectOnAppear,
      let tableView = scrollCardView.tableView,
      let selected = tableView.indexPathForSelectedRow
      else { return }
    
    if let keyboardTable = tableView as? TGKeyboardTableView, keyboardTable.selectedViaKeyboard {
      return
    }

    tableView.deselectRow(at: selected, animated: true)
  }
  
  // MARK: - Constructing views
  
  open override func buildCardView() -> TGCardView? {
    let view = TGScrollCardView.instantiate()
    view.configure(with: self)
    return view
  }
  
  open override func becomeFirstResponder() -> Bool {
    if let keyboardView = cardView?.contentScrollView as? TGKeyboardTableView {
      return keyboardView.becomeFirstResponder()
    
    } else {
      return super.becomeFirstResponder()
    }
  }
 
}

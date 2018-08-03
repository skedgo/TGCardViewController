//
//  TGCard.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

/// A card representing the content currently displayed
///
/// - warning: In normal usage, you won't use this
///     directly nor will you subclass this direct.
///     Instead you'll use the subclasses:
///
/// - `TGPlainCard`: For cards with a title and a content view
/// - `TGTableCard`: For cards with a title and table view as the content
/// - `TGCollectionCard`: For cards with a title and collection view as the
///      content
/// - `TGPageCard`: For displaying several cards on the same hierarchy,
///      allowing to swipe between them.
///
/// See those classes for more information and how to use them.
///
/// - note: Implements NSObject to make it easy to implement
/// various UIKit protocols in subclasses.
open class TGCard: NSObject, NSCoding {
  
  /// Enumeration of supported "title" configurations, i.e., what goes at the
  /// top of the card
  public enum CardTitle {
    /// Default title consisting of localized title, optional subtitle, optional
    /// accessory view, and close button
    case `default`(String, String?, UIView?)
    
    /// A customised title of your choosing. In this case, make sure to add a
    /// way to dismiss this card and call `controller?.pop()` when appropriate.
    /// You can use `TGCard.closeButtonImage` if you want to use the default
    /// style.
    case custom(UIView)
    
    /// No title at all. Make sure to call `controller?.pop()`
    /// when appropriate.
    case none
  }
  
  /// Enumeration of supported floating button styles. Use by setting
  /// `card.floatingButtonAction`.
  public enum FloatingButtonStyle {
    case add
    case custom(UIImage)
  }
  
  /// The default image for the close button on a card
  public static let closeButtonImage = TGCardStyleKit.imageOfCardCloseIcon
  
  /// The card controller currently displaying the card
  ///
  /// Set by the card controller itself
  public weak var controller: TGCardViewController?
  
  /// Optional delegate for this card
  ///
  /// Typically, `TGCardViewController` will assign itself.
  public weak var delegate: TGCardDelegate?
  
  /// Title of the card
  public let title: CardTitle
  
  /// The manager that handles the content of the map for this card
  public var mapManager: TGCompatibleMapManager? {
    didSet {
      guard let oldValue = oldValue, mapManager !== oldValue else {
        return
      }
      delegate?.mapManagerDidChange(old: oldValue, for: self)
    }
  }
  
  /// The position to display the card in, when pushing
  public let initialPosition: TGCardPosition?
  
  /// The action to execute when floating button is pressed.
  public var floatingButtonAction: (style: FloatingButtonStyle, onPressed: () -> Void)?
  
  // MARK: - Creating Cards
  
  /// Creates a new card
  ///
  /// - Parameters:
  ///   - title: Title to display
  ///   - mapManager:
  ///   - initialPosition: Position of the card when first pushed. Defaults
  ///       `.extended` if no map manager was provied.
  public init(
    title: CardTitle,
    mapManager: TGCompatibleMapManager? = nil,
    initialPosition: TGCardPosition? = nil
    ) {
    self.title = title
    self.mapManager = mapManager
    self.initialPosition = mapManager != nil ? initialPosition : .extended
  }
  
  // MARK: - Restoration
  
  public required init?(coder: NSCoder) {
    switch coder.decodeObject(forKey: "title.type") as? String {
    case "custom":
      if let view = coder.decodeView(forKey: "title.view") {
        title = .custom(view)
      } else {
        title = .none
      }
      
    case "default":
      if let title = coder.decodeObject(forKey: "title.title") as? String {
        self.title = .default(
          title,
          coder.decodeObject(forKey: "title.subtitle") as? String,
          coder.decodeView(forKey: "title.view")
        )
      } else {
        title = .none
      }
    default:
      title = .none
    }
    
    self.mapManager = coder.decodeArchived(TGCompatibleMapManager.self, forKey: "mapManager")
    if let rawPosition = coder.decodeObject(forKey: "initialPosition") as? String {
      self.initialPosition = TGCardPosition(rawValue: rawPosition)
    } else {
      self.initialPosition = .extended
    }
    self.topMapToolBarItems = coder.decodeArchived([UIView].self, forKey: "topMapToolBarItems")
    self.bottomMapToolBarItems = coder.decodeArchived([UIView].self, forKey: "bottomMapToolBarItems")
  }
  
  open func encode(with aCoder: NSCoder) {
    switch title {
    case .custom(let view):
      aCoder.encode("custom", forKey: "title.type")
      aCoder.encode(view: view, forKey: "title.view")
    case .default(let title, let subtitle, let view):
      aCoder.encode("default", forKey: "title.type")
      aCoder.encode(title, forKey: "title.title")
      aCoder.encode(subtitle, forKey: "title.subtitle")
      aCoder.encode(view: view, forKey: "title.view")
    case .none:
      aCoder.encode("none", forKey: "title.type")
    }
    
    aCoder.encodeArchive(mapManager, forKey: "mapManager")
    aCoder.encode(initialPosition?.rawValue, forKey: "initialPosition")
    aCoder.encodeArchive(topMapToolBarItems, forKey: "topMapToolBarItems")
    aCoder.encodeArchive(bottomMapToolBarItems, forKey: "bottomMapToolBarItems")
  }
  
  // MARK: - Creating Card Views.
  
  /// Each card can specify what to overlay on the top right of the map.
  ///
  /// - SeeAlso: `bottomMapToolBarItems`, if you want to overlay on the
  ///             bottom right of the map
  ///
  /// - warning: items are arranged vertically
  public var topMapToolBarItems: [UIView]?
  
  /// Each card can specify what to overlay on the bottom right of the map.
  ///
  ///- SeeAlso: `topMapToolBarItems`', if you want to overlay on the top
  ///            right of the map.
  ///
  /// - warning: items are arranged horizontally
  public var bottomMapToolBarItems: [UIView]?
  
  /// Builds the card's optional header which will be pinned to the top
  ///
  /// - SeeAlso: `TGPageCard`, which relies on this for its navigation.
  ///
  /// - Returns: Header view configured with the card's title content
  open func buildHeaderView() -> TGHeaderView? {
    return nil
  }
  
  /// Builds the card view to represent the card
  ///
  /// - Warning: Needs to be overriden by subclasses. Don't call `super`.
  ///     Don't call `didBuild`. No need to set `cardView` when done.
  ///
  /// - Parameters:
  ///   - includeTitleView: If the title view should be included or it
  ///       should be a minimal card without a title view. This is
  ///       typically `true` but set to `false` when the card is embedded
  ///       in a `TGPageCard`.
  /// - Returns: Card view configured with the content of this card
  open func buildCardView(includeTitleView: Bool) -> TGCardView {
    preconditionFailure("Override this in subclasses, but don't call super to `TGCard`.")
  }
  
  /// Called when the views have been built the first time
  ///
  /// Think of this as an equivalent of `UIViewController.viewDidLoad`
  ///
  /// - Parameters:
  ///   - cardView: The card view that got built
  ///   - headerView: The header view, typically used by `TGPageCard`.
  open func didBuild(cardView: TGCardView, headerView: TGHeaderView?) {
  }
  
  /// The card view. Gets set before `didBuild` is called
  weak var cardView: TGCardView?
  
  // MARK: - Managing Card Appearance
  
  public private(set) var viewIsVisible: Bool = false
  
  /// Each card can specify a font for title.
  ///
  /// @default Bold system font with size 17pt.
  public var titleFont: UIFont? = UIFont.boldSystemFont(ofSize: 17) {
    didSet { cardView?.applyStyling(for: self) }
  }
  
  /// Each card can specify a font for subtitle.
  ///
  /// @default Regular system font with size 15pt.
  public var subtitleFont: UIFont? = UIFont.systemFont(ofSize: 15) {
    didSet { cardView?.applyStyling(for: self) }
  }
  
  /// Each card can have its own background color.
  ///
  /// @default: white
  public var backgroundColor: UIColor? = .white {
    didSet { cardView?.applyStyling(for: self) }
  }
  
  /// Each card can specify a text color for title.
  ///
  /// @default: Black
  public var titleTextColor: UIColor? = .black {
    didSet { cardView?.applyStyling(for: self) }
  }
  
  /// Each card can specify a text color for subtitle.
  ///
  /// @default: Light grey
  public var subtitleTextColor: UIColor? = .lightGray {
    didSet { cardView?.applyStyling(for: self) }
  }
  
  // Each card can specify a color for the grab handle.
  ///
  /// @default: Grayscale @ 70%.
  public var grabHandleColor: UIColor? = #colorLiteral(red: 0.7552321553, green: 0.7552321553, blue: 0.7552321553, alpha: 1) {
    didSet { cardView?.applyStyling(for: self) }
  }
  
  /// Called to copy styling to a given card
  ///
  /// - Parameter card: card from which styling is taken.
  open func copyStyling(to card: TGCard) {
    card.titleFont = titleFont
    card.titleTextColor = titleTextColor
    card.subtitleFont = subtitleFont
    card.subtitleTextColor = subtitleTextColor
    card.backgroundColor = backgroundColor
    card.grabHandleColor = grabHandleColor
  }
  
  // MARK: - Managing Card Life Cycle
  
  /// Called just before the card becomes visible
  ///
  /// Called when card gets pushed onto a card
  /// controller, or the controller itself becomes
  /// visible.
  ///
  /// - Parameter animated: If it'll be animated
  open func willAppear(animated: Bool) {
//    print("+. \(title) will appear")
    viewIsVisible = true
  }
  
  /// Called when the card became visible
  ///
  /// - seeAlso: Notes in `willAppear`
  ///
  /// - Parameter animated: If it was animated
  open func didAppear(animated: Bool) {
//    print("++ \(title) did appear")
  }
  
  /// Called just before the card disappears
  ///
  /// Called when card gets popped from a card
  /// controller, or the controller itself disappears.
  ///
  /// - Parameter animated: If it'll be animated
  open func willDisappear(animated: Bool) {
//    print("-. \(title) will disappear")
  }
  
  /// Called when the card disappared
  ///
  /// - seeAlso: Notes in `willDisappear`
  ///
  /// - Parameter animated: If it was animated
  open func didDisappear(animated: Bool) {
//    print("-- \(title) did disappear")
    viewIsVisible = false
  }
  
  /// Called when the card moved, potentially to a new position
  ///
  /// - Parameters:
  ///   - position: The card's new position (could be same as before)
  ///   - animated: Whether it was animated or not
  open func didMove(to position: TGCardPosition, animated: Bool) {
  }
}


// MARK: -

public protocol TGCardDelegate: class {
  /// Called whenever the map manager of the card is changing
  ///
  /// The old map manager is provided, the new map manager can
  /// be access via `card.mapManager`.
  ///
  /// - Parameters:
  ///   - old: Previous map manager, if any
  ///   - card: The card whose map manager changed
  func mapManagerDidChange(old: TGCompatibleMapManager?, for card: TGCard)

  
  /// Called whenever the content scroll view of the card is changing
  ///
  /// The old scroll view is provided, the new scroll view can
  /// be access via `card.contentScrollView`.
  ///
  /// - Parameters:
  ///   - old: Previous scroll view, if any
  ///   - card: The card whose scroll view changed
  func contentScrollViewDidChange(old: UIScrollView?, for card: TGCard)
}

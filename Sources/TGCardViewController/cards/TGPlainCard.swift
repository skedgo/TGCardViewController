//
//  TGPlainCard.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

/// A plain card let's you display an arbitrary content view, accessory view,
/// along with respective map content through the map manager.
///
/// - warning: It's not recommended to use a `UITableView` or a
///     `UICollectionView` as the content. For those use the specialised
///     `TGTableCard` or `TGCollectionCard`.
///
/// This class is generally subclassed.
open class TGPlainCard: TGCard {
  
  /// The content to display on the card below title + subtitle
  ///
  /// Can be large as it will get embedded in a scroll view.
  /// Can have interactive elements.
  public let contentView: UIView?
  
  public let extended: Bool
  
  public init(
    title: CardTitle,
    contentView: UIView? = nil,
    extended: Bool = false,
    mapManager: TGCompatibleMapManager? = nil,
    initialPosition: TGCardPosition? = nil
    ) {
    assert(!(contentView is UIScrollView),
            "This card is not meant for content views that are itself" +
            "scrolling. Use `TGTableCardView` instead.")
    
    self.contentView = contentView
    self.extended = extended
    
    super.init(title: title, mapManager: mapManager, initialPosition: initialPosition)
  }
  
  public convenience init(
    title: String,
    subtitle: String? = nil,
    contentView: UIView? = nil,
    accessoryView: UIView? = nil,
    mapManager: TGCompatibleMapManager? = nil,
    initialPosition: TGCardPosition? = nil
    ) {
    
    self.init(
      title: .default(title, subtitle, accessoryView),
      contentView: contentView,
      mapManager: mapManager,
      initialPosition: initialPosition
    )
  }
  
  open override func buildCardView() -> TGCardView? {
    let view = TGPlainCardView.instantiate(extended: extended)
    view.configure(with: self)
    return view
  }
  
  open override func willAppear(animated: Bool) {
    cardView?.contentScrollView?.contentOffset = .zero
    
    super.willAppear(animated: animated)
  }
  
}

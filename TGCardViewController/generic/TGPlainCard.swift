//
//  TGPlainCard.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

/// A plain card let's you display an arbitrary content view,
/// accessory view, along with respective map content through
/// the map manager.
///
/// - warning: It's not recommended to use a `UITableView` as
///     the content. For that use `TGTableCard` instead.
///
/// This class is generally subclassed.
open class TGPlainCard: TGCard {
  
  /// The content to display on the card below title + subtitle
  ///
  /// Can be large as it will get embedded in a scroll view.
  /// Can have interactive elements.
  public let contentView: UIView?
  
  public init(
    title: TGCardTitle,
    contentView: UIView? = nil,
    mapManager: TGCompatibleMapManager? = nil,
    initialPosition: TGCardPosition? = nil
    ) {
    assert(!(contentView is UIScrollView),
            "This card is not meant for content views that are itself" +
            "scrolling. Use `TGTableCardView` instead.")
    
    self.contentView = contentView
    
    super.init(title: title, mapManager: mapManager, initialPosition: initialPosition)
  }
  
  public init(
    title: String,
    subtitle: String? = nil,
    contentView: UIView? = nil,
    accessoryView: UIView? = nil,
    mapManager: TGMapManager? = nil,
    initialPosition: TGCardPosition? = nil
    ) {
    
    assert(!(contentView is UIScrollView),
           "This card is not meant for content views that are itself" +
      "scrolling. Use `TGTableCardView` instead.")
    
    self.contentView = contentView
    super.init(
      title: .default(title, subtitle, accessoryView),
      mapManager: mapManager, initialPosition: initialPosition
    )
  }
  
  open override func buildCardView(includeTitleView: Bool) -> TGCardView {
    let view = TGPlainCardView.instantiate()
    view.configure(with: self, includeTitleView: includeTitleView)
    return view
  }
  
}

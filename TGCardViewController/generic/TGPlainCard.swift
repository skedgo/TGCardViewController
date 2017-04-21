//
//  TGPlainCard.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

open class TGPlainCard: TGCard {
  
  fileprivate var cardView: TGCardView?
  
  /// The content to display on the card below title + subtitle
  ///
  /// Can be large as it will get embedded in a scroll view.
  /// Can have interactive elements.
  let contentView: UIView?
  
  /// The view immediately below title + subtitle but above the
  /// content view.
  let accessoryView: UIView?
  
  public init(title: String, subtitle: String? = nil,
              contentView: UIView? = nil, accessoryView: UIView? = nil,
              mapManager: TGMapManager? = nil,
              initialPosition: TGCardPosition? = nil) {
    assert(!(contentView is UIScrollView),
            "This card is not meant for content views that are itself" +
            "scrolling. Use `TGTableCardView` instead.")
    
    self.contentView = contentView
    self.accessoryView = accessoryView
    
    super.init(title: title, subtitle: subtitle, mapManager: mapManager, initialPosition: initialPosition)
  }
  
  public override func buildCardView(showClose: Bool, includeHeader: Bool) -> TGCardView {
    let view = TGPlainCardView.instantiate()
    view.configure(with: self, showClose: showClose, includeHeader: includeHeader)
    view.contentScrollView?.delegate = self
    cardView = view
    return view
  }
  
}

extension TGPlainCard: UIScrollViewDelegate {
  
  fileprivate func scrollViewDidChangeContentOffset(_ scrollView: UIScrollView) {
    switch scrollView.contentOffset.y {
    case -1 * CGFloat.infinity ... 0:
      cardView?.contentSeparator?.isHidden = true
    default:
      cardView?.contentSeparator?.isHidden = false
    }
  }
  
  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    self.scrollViewDidChangeContentOffset(scrollView)
  }
  
  public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    self.scrollViewDidChangeContentOffset(scrollView)
  }
  
}

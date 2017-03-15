//
//  TGPlainCard.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TGPlainCard : TGCard {
  weak var controller: TGCardViewController?
  
  let title: String

  /// Localised optional subtitle of the card
  let subtitle: String?

  /// The content to display on the card below title + subtitle
  ///
  /// Can be large as it will get embedded in a scroll view.
  /// Can have interactive elements.
  let contentView: UIView?
  
  let bottomView: UIView?

  let mapManager: TGMapManager?
  
  init(title: String, subtitle: String? = nil, contentView: UIView? = nil, bottomView: UIView? = nil, mapManager: TGMapManager? = nil) {
    assert(!(contentView is UIScrollView), "This card is not meant for content views that are itself scrolling. Use `TGTableCardView` instead.")
    
    self.title = title
    self.subtitle = subtitle
    self.contentView = contentView
    self.mapManager = mapManager
    self.bottomView = bottomView
  }
  
  func buildView(showClose: Bool) -> TGCardView {
    let view = TGPlainCardView.instantiate()
    view.showBottomView(show: bottomView != nil)
    view.configure(with: self, showClose: showClose)
    return view
  }
  
  func willAppear(animated: Bool) { }
  
  func didAppear(animated: Bool) { }
  
  func willDisappear(animated: Bool) { }
  
  func didDisappear(animated: Bool) { }
}

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

  weak var delegate: TGCardDelegate? = nil

  let title: String

  let subtitle: String?

  /// The content to display on the card below title + subtitle
  ///
  /// Can be large as it will get embedded in a scroll view.
  /// Can have interactive elements.
  let contentView: UIView?

  let mapManager: TGMapManager?
  
  let defaultPosition: TGCardPosition
  
  init(title: String, subtitle: String? = nil, contentView: UIView? = nil, mapManager: TGMapManager? = nil, position: TGCardPosition = .peaking) {
    assert(!(contentView is UIScrollView), "This card is not meant for content views that are itself scrolling. Use `TGTableCardView` instead.")
    
    self.title = title
    self.subtitle = subtitle
    self.contentView = contentView
    self.mapManager = mapManager
    self.defaultPosition = mapManager != nil ? position : .extended
  }
  
  func buildCardView(showClose: Bool, includeHeader: Bool) -> TGCardView {
    let view = TGPlainCardView.instantiate()
    view.configure(with: self, showClose: showClose, includeHeader: includeHeader)
    return view
  }
  
  func buildHeaderView() -> TGHeaderView? {
    return nil
  }
 
  func willAppear(animated: Bool) {
//    print("+. \(title) will appear")
  }
  
  func didAppear(animated: Bool) {
//    print("++ \(title) did appear")
  }
  
  func willDisappear(animated: Bool) {
//    print("-. \(title) will disappear")
  }
  
  func didDisappear(animated: Bool) {
//    print("-- \(title) did disappear")
  }
  
}

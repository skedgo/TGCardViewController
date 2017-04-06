//
//  TGPlainCard.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

open class TGPlainCard : TGCard {
  
  weak public var controller: TGCardViewController?

  weak public var delegate: TGCardDelegate? = nil

  public let title: String

  public let subtitle: String?

  /// The content to display on the card below title + subtitle
  ///
  /// Can be large as it will get embedded in a scroll view.
  /// Can have interactive elements.
  let contentView: UIView?

  public let mapManager: TGMapManager?
  
  public let defaultPosition: TGCardPosition
  
  public init(title: String, subtitle: String? = nil, contentView: UIView? = nil, mapManager: TGMapManager? = nil, position: TGCardPosition = .peaking) {
    assert(!(contentView is UIScrollView), "This card is not meant for content views that are itself scrolling. Use `TGTableCardView` instead.")
    
    self.title = title
    self.subtitle = subtitle
    self.contentView = contentView
    self.mapManager = mapManager
    self.defaultPosition = mapManager != nil ? position : .extended
  }
  
  public func buildCardView(showClose: Bool, includeHeader: Bool) -> TGCardView {
    let view = TGPlainCardView.instantiate()
    view.configure(with: self, showClose: showClose, includeHeader: includeHeader)
    return view
  }
  
  public func buildHeaderView() -> TGHeaderView? {
    return nil
  }
 
  open func didBuild(cardView: TGCardView, headerView: TGHeaderView?) {
  }
  
  open func willAppear(animated: Bool) {
//    print("+. \(title) will appear")
  }
  
  open func didAppear(animated: Bool) {
//    print("++ \(title) did appear")
  }
  
  open func willDisappear(animated: Bool) {
//    print("-. \(title) will disappear")
  }
  
  open func didDisappear(animated: Bool) {
//    print("-- \(title) did disappear")
  }
  
}

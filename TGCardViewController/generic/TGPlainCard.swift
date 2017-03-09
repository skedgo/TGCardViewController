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
  let subtitle: String?
  let contentView: UIView?
  
  init(title: String, subtitle: String? = nil, contentView: UIView? = nil) {
    self.title = title
    self.subtitle = subtitle
    self.contentView = contentView
  }
  
  func buildView(showClose: Bool) -> TGCardView {
    let view = TGPlainCardView.instantiate()
    view.configure(with: self, showClose: showClose)
    return view
  }
  
  func willAppear(animated: Bool) { }
  
  func didAppear(animated: Bool) { }
  
  func willDisappear(animated: Bool) { }
  
  func didDisappear(animated: Bool) { }
}

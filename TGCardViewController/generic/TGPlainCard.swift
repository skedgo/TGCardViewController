//
//  TGPlainCard.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

struct TGPlainCard : TGCard {
  let title: String
  let subtitle: String?
  let contentView: UIView?
  
  init(title: String, subtitle: String? = nil, contentView: UIView? = nil) {
    self.title = title
    self.subtitle = subtitle
    self.contentView = contentView
  }
  
  func buildView() -> UIView {
    let view = TGPlainCardView.instantiate()
    view.configure(with: self, showClose: true)
    return view
  }
}

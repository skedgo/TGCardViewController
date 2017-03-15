//
//  TGPlainCardView.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TGPlainCardView: TGCardView {

  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subtitleLabel: UILabel!

  @IBOutlet weak var contentView: UIView!
  
  static func instantiate() -> TGPlainCardView {
    let bundle = Bundle(for: self)
    return bundle.loadNibNamed("TGPlainCardView", owner: nil, options: nil)!.first as! TGPlainCardView
  }
  
  func configure(with card: TGPlainCard, showClose: Bool) {
    titleLabel.text = card.title
    subtitleLabel.text = card.subtitle
    closeButton.isHidden = !showClose
    
    if let content = card.contentView {
      content.translatesAutoresizingMaskIntoConstraints = false
      contentView.addSubview(content)
      content.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
      content.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
      contentView.trailingAnchor.constraint(equalTo: content.trailingAnchor).isActive = true
      contentView.bottomAnchor.constraint(equalTo: content.bottomAnchor).isActive = true
    }
  }
}

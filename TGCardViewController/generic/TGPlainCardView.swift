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

  @IBOutlet weak var scrollView: UIScrollView!
  
  static func instantiate() -> TGPlainCardView {
    let bundle = Bundle(for: self)
    return bundle.loadNibNamed("TGPlainCardView", owner: nil, options: nil)!.first as! TGPlainCardView
  }
  
  func configure(with card: TGPlainCard, showClose: Bool) {
    titleLabel.text = card.title
    subtitleLabel.text = card.subtitle
    
    closeButton.isHidden = !showClose
    
    if let content = card.contentView {
      scrollView.addSubview(content)
      scrollView.contentSize = content.frame.size
    }
  }
}

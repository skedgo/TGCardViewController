//
//  TGPlainCardView.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TGPlainCardView: TGCardView {

  @IBOutlet weak var contentView: UIView!
  
  static func instantiate() -> TGPlainCardView {
    let bundle = Bundle(for: self)
    guard
      let view = bundle.loadNibNamed("TGPlainCardView", owner: nil, options: nil)!.first as? TGPlainCardView
      else { preconditionFailure() }
    return view

  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    closeButton?.setImage(TGCardStyleKit.imageOfCardCloseIcon, for: .normal)
    closeButton?.setTitle(nil, for: .normal)
    closeButton?.accessibilityLabel = NSLocalizedString("Close", comment: "Close button accessory title")
  }
  
  func configure(with card: TGPlainCard, showClose: Bool, includeHeader: Bool) {
    super.configure(with: card, showClose: showClose, includeHeader: includeHeader)
    
    if includeHeader {
      accessoryView = card.accessoryView
    }
    
    self.floatingButtonAction = card.floatingButtonAction
    
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

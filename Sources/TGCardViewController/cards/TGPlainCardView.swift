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
  @IBOutlet weak var contentViewHeightEqualToSuperviewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var titleViewPlaceholderHeight: NSLayoutConstraint!
  
  // MARK: - New instances
  
  static func instantiate() -> TGPlainCardView {
    guard
      let view = Bundle.cardVC.loadNibNamed("TGPlainCardView", owner: nil, options: nil)!.first as? TGPlainCardView
      else { preconditionFailure() }
    return view
  }
  
  // MARK: - Configuration
  
  override func configure(with card: TGCard) {
    guard let plainCard = card as? TGPlainCard else {
      preconditionFailure()
    }
    
    super.configure(with: plainCard)
    
    // build the header
    var adjustment: CGFloat = 1.0 // accounted for the separator
    if let titleViewPlaceHolder = titleViewPlaceholder {
      let height = titleViewPlaceHolder.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
      adjustment += height
    }
    if let handle = grabHandle {
      adjustment += handle.frame.height
    }
    contentViewHeightEqualToSuperviewHeightConstraint.constant = -1*adjustment
    
    // build the main content
    if let content = plainCard.contentView {
      content.translatesAutoresizingMaskIntoConstraints = false
      contentView.addSubview(content)
      content.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
      content.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
      contentView.trailingAnchor.constraint(equalTo: content.trailingAnchor).isActive = true
      contentView.bottomAnchor.constraint(equalTo: content.bottomAnchor).isActive = true
    }
  }
  
}

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
  
  static func instantiate(extended: Bool) -> TGPlainCardView {
    guard
      let view = TGCardViewController.bundle.loadNibNamed(extended ? "TGPlainExtendedCardView" : "TGPlainCardView", owner: nil, options: nil)!.first as? TGPlainCardView
      else { preconditionFailure() }
    return view
  }
  
  // MARK: - Configuration
  
  func configure(with card: TGCard, contentView: UIView?) {
    super.configure(with: card)
    
    // build the header
    var adjustment: CGFloat = 1.0 // accounted for the separator
    if let titleViewPlaceHolder = titleViewPlaceholder {
      let height = titleViewPlaceHolder.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
      adjustment += height
    }
    if let handle = grabHandle {
      adjustment += handle.frame.height
    }
    
    if card.title.isExtended {
      contentScrollView?.contentInset.top = adjustment
    } else {
      contentViewHeightEqualToSuperviewHeightConstraint.constant = -1*adjustment
    }
    
    // build the main content
    if let content = contentView {
      content.translatesAutoresizingMaskIntoConstraints = false
      self.contentView.addSubview(content)
      content.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
      content.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
      self.contentView.trailingAnchor.constraint(equalTo: content.trailingAnchor).isActive = true
      self.contentView.bottomAnchor.constraint(equalTo: content.bottomAnchor).isActive = true
    }
  }
  
}

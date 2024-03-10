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
    
    if plainCard.extended {
      contentScrollView?.contentInset.top = adjustment
    } else {
      contentViewHeightEqualToSuperviewHeightConstraint.constant = -1*adjustment
    }
    
    
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
  
  override func showSeparator(_ show: Bool, offset: CGFloat) {
    if let owningCard, owningCard.shouldToggleSeparator(show: show, offset: offset) {
      super.showSeparator(show, offset: offset)
      
    } else if (owningCard as? TGPlainCard)?.extended == true, let contentScrollView, contentScrollView.isDecelerating, offset < 0 {
      // This handles the case where you fling the content down further than the
      // top. It looks wierd if this would then scroll or bounce into negative
      // space, so we just stop apruptly at 0.
      // We consider `.isDecelerating` to let you do this while actively
      // dragging, to not stop that gesture, as that would brea, dragging the
      // card down by the scroll view, when you start with a scroll.
      contentScrollView.contentOffset.y = 0
    }
  }
  
  override func adjustContentAlpha(to value: CGFloat) {
    owningCard?.willAdjustContentAlpha(value)
    super.adjustContentAlpha(to: value)
  }
  
}

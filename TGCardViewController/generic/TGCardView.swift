//
//  TGCardView.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TGCardView: TGCornerView {
  
  /// Each card view needs a grab handle, which the controller
  /// might hide and show.
  @IBOutlet weak var grabHandle: TGGrabHandleView?
  
  /// The stack view that houses the title and subtitle labels.
  ///
  /// This outlet exists so that we can adjust the spacing between
  /// labels if necessary.
  @IBOutlet weak var labelStack: UIStackView?
  
  /// This is the constraint that connects the top of the header 
  /// stack view to the bottom of the grab handle. Together with
  /// the `headerStackBottomConstraint`, we can control the amount
  /// of white spaces when header isn't required.
  @IBOutlet weak var headerStackTopConstraint: NSLayoutConstraint?
  
  /// This is the constraint that connects the bottom of the header
  /// stack view to the top of the content view. See also
  /// `headerStackTopConstraint'.
  @IBOutlet weak var headerStackBottomConstraint: NSLayoutConstraint?
  
  /// Each card view needs a close button, which the card controller
  /// will add itself as a target to in order to pop the current card
  /// from the stack.
  @IBOutlet weak var closeButton: UIButton?
  
  /// Each card view needs a scroll view where the main content of the
  /// card goes. The card controller need access to it, in order to
  /// handling dragging the card up and down.
  @IBOutlet weak var contentScrollView: UIScrollView?
  
  @IBOutlet weak var titleLabel: UILabel!
  
  @IBOutlet weak var subtitleLabel: UILabel!
  
  var pagingScrollView: UIScrollView?
  
  var headerHeight: CGFloat {
    guard let scrollView = contentScrollView else { return 0 }
    return scrollView.frame.minY
  }
  
  // MARK: - Configuration
  
  func configure(with card: TGCard, showClose: Bool, includeHeader: Bool) {
    titleLabel.text = includeHeader ? card.title : nil
    subtitleLabel.text = includeHeader ? card.subtitle : nil
    closeButton?.isHidden = !showClose
    labelStack?.spacing = includeHeader ? 3 : 0
    headerStackTopConstraint?.constant = includeHeader ? 8 : 0
    headerStackBottomConstraint?.constant = includeHeader ? 8 : 0
  }
  
  func allowContentScrolling(_ allowScrolling: Bool) {
    contentScrollView?.isScrollEnabled = allowScrolling
  }
  
}

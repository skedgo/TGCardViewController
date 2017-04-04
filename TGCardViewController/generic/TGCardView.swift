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
  
  /// The stack view that contains the label stack and the 
  /// accessory view.
  @IBOutlet private weak var headerStack: UIStackView?
  
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
  
  /// Each card view needs a place to display the card's title.
  @IBOutlet weak var titleLabel: UILabel!
  
  /// Each card view needs a place to display the card's subtitle.
  @IBOutlet weak var subtitleLabel: UILabel!
  
  /// Optional pager in which `contentScrollView` can be wrapped.
  ///
  /// - SeeAlso: `TGPageCardView` which relies on this.
  var pagingScrollView: UIScrollView?
  
  /// The height of the header part of the view, i.e., everything
  /// up to where `contentScrollView` starts.
  ///
  /// - Warning: Might not be accurate if the view hasn't been layed out.
  var headerHeight: CGFloat {
    guard let scrollView = contentScrollView else { return 0 }
    return scrollView.frame.minY
  }
  
  @IBOutlet private weak var accessoryWrapperView: UIView!
  
  /// Optional view beneath title + subtitle.
  var accessoryView: UIView? {
    get {
      return accessoryWrapperView.subviews.first
    }
    set {
      guard let view = newValue else {
        accessoryWrapperView.subviews.forEach { $0.removeFromSuperview() }
        accessoryWrapperView.isHidden = true
        headerStack?.spacing = 0
        return
      }
      
      accessoryWrapperView.addSubview(view)
      view.snap(to: accessoryWrapperView)
      accessoryWrapperView.isHidden = false
      headerStack?.spacing = 4
    }
  }
  
  // MARK: - Configuration
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    // Here we set the minimum width and height to provide sufficient hit
    // target. The priority is lowered because we may need to hide the
    // button and in such case, stack view will reduce its size to zero,
    // hence creating conflicting constraints.
    let widthConstraint = closeButton?.widthAnchor.constraint(equalToConstant: 44)
    widthConstraint?.priority = 999
    widthConstraint?.isActive = true
    
    let heightConstraint = closeButton?.heightAnchor.constraint(equalToConstant: 44)
    heightConstraint?.priority = 999
    heightConstraint?.isActive = true
  }
  
  func configure(with card: TGCard, showClose: Bool, includeHeader: Bool) {
    titleLabel.text = includeHeader ? card.title : nil
    subtitleLabel.text = includeHeader ? card.subtitle : nil
    closeButton?.isHidden = !showClose
    labelStack?.spacing = includeHeader && card.subtitle != nil ? 3 : 0
    headerStackTopConstraint?.constant = includeHeader ? 8 : 0
    headerStackBottomConstraint?.constant = includeHeader ? 8 : 0
  }
  
  func allowContentScrolling(_ allowScrolling: Bool) {
    contentScrollView?.isScrollEnabled = allowScrolling
  }
  
}

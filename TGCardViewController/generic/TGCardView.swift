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
  
  /// Each card view needs a close button, which the card controller
  /// will add itself as a target to in order to pop the current card
  /// from the stack.
  @IBOutlet weak var closeButton: UIButton?
  
  /// Each card view needs a scroll view where the main content of the
  /// card goes. The card controller need access to it, in order to
  /// handling dragging the card up and down.
  @IBOutlet weak var scrollView: UIScrollView?
  
  var pagingScrollView: UIScrollView?
  
  var contentScrollViews: [UIScrollView] {
    guard let scrollView = scrollView else { return [] }
    return [scrollView]
  }
  
  var headerHeight: CGFloat {
    guard let scrollView = scrollView else { return 0 }
    return scrollView.frame.minY
  }
  
  // MARK: - Configuration
  
  func allowContentScrolling(_ allowScrolling: Bool) {
    contentScrollViews.forEach { $0.isScrollEnabled = allowScrolling }
  }
  
}

//
//  TGCardView.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TGCardView: UIView {
  
  /// Each card view needs a close button, which the card controller
  /// will add itself as a target to in order to pop the current card
  /// from the stack.
  @IBOutlet weak var closeButton: UIButton!
  
  /// Each card view needs a scroll view where the main content of the
  /// card goes. The card controller need access to it, in order to
  /// handling dragging the card up and down.
  @IBOutlet weak var scrollView: UIScrollView!
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 10, height: 10))
    let mask = CAShapeLayer()
    mask.path = path.cgPath
    layer.mask = mask
  }
  
}

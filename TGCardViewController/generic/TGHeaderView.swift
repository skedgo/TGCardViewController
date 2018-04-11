//
//  TGHeaderView.swift
//  TGCardViewController
//
//  Created by Adrian Schönig on 09.04.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

/// A view that can be placed as the header view of a card, i.e., pinned
/// to the top of the screen above the card.
///
/// - Note: Header views need to have a fixed height!
open class TGHeaderView: UIView {
  
  @IBOutlet public weak var closeButton: UIButton?
  @IBOutlet public weak var rightButton: UIButton?
  
  open var cornerRadius: CGFloat = 0
}

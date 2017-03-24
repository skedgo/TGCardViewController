//
//  TGHeaderView.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 24/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TGHeaderView : UIView {
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subtitleLabel: UILabel!
  
  @IBOutlet weak var closeButton: UIButton!
  @IBOutlet weak var rightButton: UIButton!
  
  @IBOutlet weak var accessoryWrapperView: UIView!
  
  static func instantiate() -> TGHeaderView {
    let bundle = Bundle(for: self)
    return bundle.loadNibNamed("TGHeaderView", owner: nil, options: nil)!.first as! TGHeaderView
  }
  
  
  override func awakeFromNib() {
    titleLabel.text = nil
    subtitleLabel.text = nil
    rightButton.isHidden = true
    accessoryWrapperView.isHidden = true
  }
  
  
  var accessoryView: UIView? {
    get {
      return accessoryWrapperView.subviews.first
    }
    set {
      guard let view = accessoryView else {
        accessoryWrapperView.subviews.forEach { $0.removeFromSuperview() }
        return
      }
      
      accessoryWrapperView.addSubview(view)
    }
  }
  
  
  var rightAction: ((Void) -> Void)? {
    didSet {
      rightButton?.isHidden = (rightAction == nil)
    }
  }
  
  
  // MARK: - Button actions
  
  @IBAction func rightButtonTapped(_ sender: UIButton) {
    rightAction?()
  }
  
}

//
//  TGCardDefaultTitleView.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 10/4/18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TGCardDefaultTitleView: UIView {
  
  @IBOutlet weak var topLevelStack: UIStackView!
  @IBOutlet weak var labelStack: UIStackView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subtitleLabel: UILabel!
  @IBOutlet weak var dismissButton: UIButton!
  @IBOutlet weak var accessoryViewContainer: UIView!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    // Here we set the minimum width and height to provide sufficient hit
    // target. The priority is lowered because we may need to hide the
    // button and in such case, stack view will reduce its size to zero,
    // hence creating conflicting constraints.
    let widthConstraint = dismissButton.widthAnchor.constraint(equalToConstant: 44)
    widthConstraint.priority = .defaultHigh
    widthConstraint.isActive = true
    
    let heightConstraint = dismissButton.heightAnchor.constraint(equalToConstant: 44)
    heightConstraint.priority = .defaultHigh
    heightConstraint.isActive = true
  }
  
  // MARK: - Creating New Views
  
  static func newInstance() -> TGCardDefaultTitleView {
    let bundle = Bundle(for: self)
    return bundle.loadNibNamed("TGCardDefaultTitleView", owner: self, options: nil)?.first as! TGCardDefaultTitleView
  }
  
  // MARK: - Content Configuration
  
  var accessoryView: UIView? {
    get {
      return accessoryViewContainer.subviews.first
    }
    set {
      // Start clean
      accessoryViewContainer.subviews.forEach { $0.removeFromSuperview() }
      
      guard let newView = newValue else {
        accessoryViewContainer.isHidden = true
        topLevelStack.spacing = 0
        return
      }
      
      accessoryViewContainer.addSubview(newView)
      newView.snap(to: accessoryViewContainer)
      accessoryViewContainer.isHidden = false
      topLevelStack.spacing = 4
      
      setNeedsLayout()
    }
  }
  
  func configure(with card: TGCard, canBeDismissed: Bool) {
    titleLabel.text = card.title
    subtitleLabel.text = card.subtitle
    dismissButton.isHidden = !canBeDismissed
    labelStack.spacing = card.subtitle != nil ? 3 : 0
    dismissButton.setImage(TGCardStyleKit.imageOfCardCloseIcon, for: .normal)
    dismissButton.setTitle(nil, for: .normal)
  }

}

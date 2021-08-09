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
  
  // By default, the top level stack snaps to all edges
  // of the default title view. The space to the bottom
  // edge is exposed, so that we can allow the accessory
  // view to set its desired spacing.
  @IBOutlet private weak var topLevelStackBottomSpace: NSLayoutConstraint!
  
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
    // swiftlint:disable force_cast
    return Bundle.module.loadNibNamed("TGCardDefaultTitleView", owner: self, options: nil)?.first as! TGCardDefaultTitleView
    // swiftlint:enable force_cast

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
        
        // If an accessory view is not provided, use a default
        // spacing to the bottom edge of the title view.
        topLevelStackBottomSpace.constant = 16
        return
      }
      
      accessoryViewContainer.addSubview(newView)
      newView.snap(to: accessoryViewContainer)
      accessoryViewContainer.isHidden = false
      topLevelStack.spacing = 16
      
      // If accessory view is present, let is specify the needed
      // spacing to the bottom edge of the title view.
      topLevelStackBottomSpace.constant = 0
      
      setNeedsLayout()
    }
  }

  func prepare(title: String, subtitle: String?, style: TGCardStyle) {
    configure(title: title, subtitle: subtitle, style: style, isInitial: true)
  }


  func update(title: String, subtitle: String?, style: TGCardStyle) {
    configure(title: title, subtitle: subtitle, style: style, isInitial: false)
  }

  private func configure(title: String, subtitle: String?, style: TGCardStyle, isInitial: Bool) {
    titleLabel.text = title
    titleLabel.font = style.titleFont
    titleLabel.textColor = style.titleTextColor
    
    subtitleLabel.text = subtitle
    subtitleLabel.font = style.subtitleFont
    subtitleLabel.textColor = style.subtitleTextColor
    
    if isInitial {
      dismissButton.isHidden = false
      let closeButtonImage = TGCardStyleKit.imageOfCardCloseIcon(
        closeButtonBackground: style.closeButtonBackgroundColor,
        closeButtonCross: style.closeButtonCrossColor
      )
      dismissButton.setImage(closeButtonImage, for: .normal)
      dismissButton.setTitle(nil, for: .normal)
    }
  }
  
}

extension TGCardDefaultTitleView: TGInteractiveCardTitle {
  
  func interactiveFrame(relativeTo cardView: TGCardView) -> CGRect? {
    guard let accessory = accessoryViewContainer.subviews.first else { return nil }
    return accessoryViewContainer.convert(accessory.frame, to: cardView)
  }
  
}

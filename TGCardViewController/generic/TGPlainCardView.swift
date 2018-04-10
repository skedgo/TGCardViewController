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
  
  // MARK: - New instances
  
  static func instantiate() -> TGPlainCardView {
    let bundle = Bundle(for: self)
    guard
      let view = bundle.loadNibNamed("TGPlainCardView", owner: nil, options: nil)!.first as? TGPlainCardView
      else { preconditionFailure() }
    return view
  }
  
  // MARK: - Configuration
  
  override func titleAccessoryView(for card: TGCard) -> UIView? {
    guard let plainCard = card as? TGPlainCard else {
      return nil
    }
    return plainCard.accessoryView
  }
  
  override func configure(with card: TGCard, includeTitleView: Bool) {
    guard let plainCard = card as? TGPlainCard else {
      preconditionFailure()
    }
    
    super.configure(with: plainCard, includeTitleView: includeTitleView)
    
    if let content = plainCard.contentView {
      content.translatesAutoresizingMaskIntoConstraints = false
      contentView.addSubview(content)
      content.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
      content.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
      contentView.trailingAnchor.constraint(equalTo: content.trailingAnchor).isActive = true
      contentView.bottomAnchor.constraint(equalTo: content.bottomAnchor).isActive = true
    }
  }
  
}

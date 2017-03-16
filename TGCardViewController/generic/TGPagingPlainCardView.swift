//
//  TGPagingCardView.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 16/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TGPagingPlainCardView: TGCardView {
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subtitleLabel: UILabel!
  
  /// This is where the contents for the scroll view go.
  @IBOutlet weak var contentView: UIView!
  
  static func instantiate() -> TGPagingPlainCardView {
    let bundle = Bundle(for: self)
    return bundle.loadNibNamed("TGPagingPlainCardView", owner: nil, options: nil)!.first as! TGPagingPlainCardView
  }
  
  func configure(with card: TGPagingPlainCard, dismissable: Bool) {
    titleLabel.text = card.title
    subtitleLabel.text = card.subtitle
    closeButton.isHidden = !dismissable
    
    var previous: UIView!
    
    for (index, view) in card.contentViews.enumerated() {
      view.translatesAutoresizingMaskIntoConstraints = false
      contentView.addSubview(view)
      
      if index == 0 {
        view.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
      } else {
        view.leadingAnchor.constraint(equalTo: previous.trailingAnchor).isActive = true
      }
      
      view.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
      view.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
      view.widthAnchor.constraint(equalTo: self.contentView.widthAnchor).isActive = true
      
      if index == card.contentViews.count - 1 {
        view.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
      }
      
      previous = view
    }
  }
}

//
//  TGScrollCardView.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 18/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TGScrollCardView: TGCardView {
  
  @IBOutlet weak var contentView: UIView!
  
  // MARK: - New instance
  
  static func instantiate() -> TGScrollCardView {
    let bundle = Bundle(for: self)
    return bundle.loadNibNamed("TGScrollCardView", owner: nil, options: nil)!.first as! TGScrollCardView
  }
  
  // MARK: - Configuration
  
  func configure(with card: TGScrollCard) {
    let contents = card.contentCards.map { $0.buildView(showClose: true) }
    fill(with: contents)
  }
  
  private func fill(with contentViews: [UIView]) {
    // This is required to make connection from the leading edge
    // of the nth content view to the trailing edge of the (n-1)
    // content view.
    var previous: UIView!
    
    for (index, view) in contentViews.enumerated() {
      view.translatesAutoresizingMaskIntoConstraints = false
      self.contentView.addSubview(view)
      
      if index == 0 {
        // First content needs to be connected to the scroll
        // view's content view.
        view.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
      } else {
        // Subsequent, non-last, content is connected to its
        // preceding sibling.
        view.leadingAnchor.constraint(equalTo: previous.trailingAnchor).isActive = true
      }
      
      // All contents are connected to the top and bottom edges
      // of the scroll view's content.
      view.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
      view.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
      
      // All contents have the same width, which equals to the width of
      // the scroll view. Note that, scroll view is used here, instead
      // of its content view.
      view.widthAnchor.constraint(equalTo: self.scrollView.widthAnchor).isActive = true
      
      // The last content is connected to the trailing edge of the
      // scroll view's content view.
      if index == contentViews.count - 1 {
        view.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
      }
      
      previous = view
    }
  }
  
  
  
}

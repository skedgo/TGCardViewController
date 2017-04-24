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
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    closeButton?.setImage(TGCardStyleKit.imageOfCardCloseIcon, for: .normal)
    closeButton?.setTitle(nil, for: .normal)
    closeButton?.accessibilityLabel = NSLocalizedString("Close", comment: "Close button accessory title")
  }
  
  // MARK: - Configuration
  
  override func configure(with card: TGCard, showClose: Bool, includeHeader: Bool) {
    guard let card = card as? TGPlainCard else {
      preconditionFailure()
    }
    
    super.configure(with: card, showClose: showClose, includeHeader: includeHeader)
    
    contentScrollView?.addObserver(self, forKeyPath: "contentOffset", options: [.new], context: nil)
    
    if includeHeader {
      accessoryView = card.accessoryView
    }
    
    if let content = card.contentView {
      content.translatesAutoresizingMaskIntoConstraints = false
      contentView.addSubview(content)
      content.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
      content.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
      contentView.trailingAnchor.constraint(equalTo: content.trailingAnchor).isActive = true
      contentView.bottomAnchor.constraint(equalTo: content.bottomAnchor).isActive = true
    }
  }
  
  // MARK: - KVO
  
  deinit {
    contentScrollView?.removeObserver(self, forKeyPath: "contentOffset")
  }
  
  public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    guard
      let path = keyPath,
      path == "contentOffset",
      let separator = contentSeparator,
      let scroller = contentScrollView,
      scroller.isScrollEnabled == true
      else { return }
    
    if let point = change?[NSKeyValueChangeKey.newKey] as? CGPoint {
      separator.isHidden = point.y <= 0
    }
  }
}

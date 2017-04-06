//
//  TGGrabHandleView.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 13/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TGGrabHandleView: UIView {
  
  private var handleHeightConstraint: NSLayoutConstraint?
  private var handleTopSpaceConstraint: NSLayoutConstraint?
  private var handleBottomSpaceConstraint: NSLayoutConstraint?

  override init(frame: CGRect) {
    super.init(frame: frame)
    didInit()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    didInit()
  }
  
  private func didInit() {
    let handle = UIView()
    handle.layer.cornerRadius = 3
    handle.backgroundColor = UIColor(white: 0.7, alpha: 1.0)
    handle.translatesAutoresizingMaskIntoConstraints = false
    addSubview(handle)
    
    handle.widthAnchor.constraint(equalToConstant: 50).isActive = true
    handle.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    
    // We keep references to the following constraints because they need
    // to be adjusted when the handle is hideen. See `isHidden`.
    let heightConstraint = handle.heightAnchor.constraint(equalToConstant: 5)
    self.handleHeightConstraint = heightConstraint
    
    let topSpaceConstraint = handle.topAnchor.constraint(equalTo: topAnchor, constant: 8)
    self.handleTopSpaceConstraint = topSpaceConstraint
    
    let bottomSpaceConstraint = bottomAnchor.constraint(equalTo: handle.bottomAnchor, constant: 8)
    self.handleBottomSpaceConstraint = bottomSpaceConstraint
    
    [heightConstraint, topSpaceConstraint, bottomSpaceConstraint].forEach { $0.isActive = true }
  }
  
  override var isHidden: Bool {
    didSet {
      handleHeightConstraint?.constant = isHidden ? 0 : 5
      handleTopSpaceConstraint?.constant = isHidden ? 0 : 8
      handleBottomSpaceConstraint?.constant = isHidden ? 0 : 8
    }
  }
}

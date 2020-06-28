//
//  TGGrabHandleView.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 13/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TGGrabHandleView: UIView {

  // MARK: - Creating New Grab Handle Views
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    didInit()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    didInit()
  }
  
  private func didInit() {
    backgroundColor = .clear
    
    let handle = UIView()
    handle.layer.cornerRadius = 2
    handle.backgroundColor = #colorLiteral(red: 0.13, green: 0.16, blue: 0.2, alpha: 0.18)
    handle.translatesAutoresizingMaskIntoConstraints = false
    addSubview(handle)
    self.handle = handle
    
    // Position the handle
    NSLayoutConstraint.activate([
      handle.widthAnchor.constraint(equalToConstant: 48),
      handle.centerXAnchor.constraint(equalTo: centerXAnchor)
      ])
    
    // We keep references to the following constraints because they need
    // to be adjusted when the handle is hideen. See `isHidden`.
    let handleHeightConstraint = handle.heightAnchor.constraint(equalToConstant: 4)
    self.handleHeightConstraint = handleHeightConstraint
    
    let handleTopSpaceConstraint = handle.topAnchor.constraint(equalTo: topAnchor, constant: 6)
    self.handleTopSpaceConstraint = handleTopSpaceConstraint
    
    let handleBottomSpaceConstraint = bottomAnchor.constraint(equalTo: handle.bottomAnchor, constant: 6)
    self.handleBottomSpaceConstraint = handleBottomSpaceConstraint
    
    NSLayoutConstraint.activate([handleHeightConstraint, handleTopSpaceConstraint, handleBottomSpaceConstraint])
  }
  
  // MARK: - Layout Support
  
  private var handleHeightConstraint: NSLayoutConstraint?
  private var handleTopSpaceConstraint: NSLayoutConstraint?
  private var handleBottomSpaceConstraint: NSLayoutConstraint?
  
  // MARK: - Managing Handle Appearance
  
  private(set) var handle: UIView!
  
  var handleColor: UIColor? {
    willSet {
      handle.backgroundColor = newValue ?? UIColor(white: 0.7, alpha: 1.0)
    }
  }
  
  override var isHidden: Bool {
    didSet {
      handleHeightConstraint?.constant = isHidden ? 0 : 5
      handleTopSpaceConstraint?.constant = isHidden ? 0 : 8
      handleBottomSpaceConstraint?.constant = isHidden ? 0 : 8
      setNeedsUpdateConstraints()
    }
  }
}

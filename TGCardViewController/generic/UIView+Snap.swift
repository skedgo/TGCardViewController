//
//  UIView+Snap.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 27/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

extension UIView {
  
  public func snap(to superView: UIView) {
    translatesAutoresizingMaskIntoConstraints = false
    topAnchor.constraint(equalTo: superView.topAnchor).isActive = true
    leadingAnchor.constraint(equalTo: superView.leadingAnchor).isActive = true
    trailingAnchor.constraint(equalTo: superView.trailingAnchor).isActive = true
    bottomAnchor.constraint(equalTo: superView.bottomAnchor).isActive = true
  }
  
  func center(on superView: UIView) {
    translatesAutoresizingMaskIntoConstraints = false
    superView.addSubview(self)
    topAnchor.constraint(equalTo: superView.topAnchor, constant: 8).isActive = true
    centerXAnchor.constraint(equalTo: superView.centerXAnchor).isActive = true
    centerYAnchor.constraint(equalTo: superView.centerYAnchor).isActive = true
  }
  
}

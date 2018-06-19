//
//  UIView+Snap.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 27/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

extension UIView {
  
  func snap(to superView: UIView, margin: CGFloat = 0) {
    translatesAutoresizingMaskIntoConstraints = false    
    NSLayoutConstraint.activate([
        topAnchor.constraint(equalTo: superView.topAnchor, constant: margin),
        leadingAnchor.constraint(equalTo: superView.leadingAnchor, constant: margin),
        trailingAnchor.constraint(equalTo: superView.trailingAnchor, constant: -1*margin),
        bottomAnchor.constraint(equalTo: superView.bottomAnchor, constant: -1*margin)
      ])
  }
  
  func center(on superView: UIView) {
    translatesAutoresizingMaskIntoConstraints = false
    superView.addSubview(self)
    topAnchor.constraint(equalTo: superView.topAnchor, constant: 8).isActive = true
    centerXAnchor.constraint(equalTo: superView.centerXAnchor).isActive = true
    centerYAnchor.constraint(equalTo: superView.centerYAnchor).isActive = true
  }
  
}

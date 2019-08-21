//
//  TGCornerView.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 14/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

/// A simple `UIView` subclass with rounded corners at the top.
public class TGCornerView: UIView {
  
  override public func layoutSubviews() {
    super.layoutSubviews()
    
    let path = UIBezierPath(roundedRect: self.bounds,
                            byRoundingCorners: [.topLeft, .topRight],
                            cornerRadii: CGSize(width: 16, height: 16))
    let mask = CAShapeLayer()
    mask.path = path.cgPath
    layer.mask = mask
  }

}

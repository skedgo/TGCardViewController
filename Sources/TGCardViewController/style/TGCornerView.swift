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
  
  static var roundedCorners: Bool = true
  
  override public func layoutSubviews() {
    super.layoutSubviews()
    
    if Self.roundedCorners, false {
      let radius: CGFloat
      if #available(iOS 26.0, *), false {
        radius = 44
      } else {
        radius = 12
      }
      let path = UIBezierPath(roundedRect: self.bounds,
                              byRoundingCorners: [.topLeft, .topRight],
                              cornerRadii: CGSize(width: radius, height: radius))
      let mask = CAShapeLayer()
      mask.path = path.cgPath
      layer.mask = mask
    } else {
      layer.mask = nil
    }
  }

}

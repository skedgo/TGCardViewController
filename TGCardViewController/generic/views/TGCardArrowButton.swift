//
//  TGCardArrowButton.swift
//  TGCardViewController
//
//  Created by Adrian Schönig on 02.08.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

public enum TGArrowDirection {
  case up
  case down
}

class TGCardArrowButton: UIControl {
  
  var arrowColor: UIColor = .darkText
  var circleColor: UIColor = UIColor.darkText.withAlphaComponent(0.25)
  
  var arrowDirection: TGArrowDirection = .up
  
  override func draw(_ rect: CGRect) {
    TGCardStyleKit.drawCardArrowIcon(
      frame: bounds, resizing: .aspectFit,
      closeButtonBackground: circleColor, closeButtonCross: arrowColor,
      arrowRotation: arrowDirection == .up ? 0 : 90
    )
  }
  
}

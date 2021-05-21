//
//  TGButtonPosition.swift
//  TGCardViewController
//
//  Created by Adrian Schönig on 04.04.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

public enum TGButtonPosition {
  /// In the top right of the map, underneath the status bar
  case top
  
  /// In the bottom right of the map, floating on top of the
  /// card (if the card is at the bottom rather fixed to the
  /// left of the screen)
  case bottom
}

public struct TGButtonStyle {
  /// Default style is rounded rect, no special tint colour and translucent
  public init(shape: TGButtonStyle.Shape = .roundedRect, tintColor: UIColor? = nil, isTranslucent: Bool = true) {
    self.shape = shape
    self.tintColor = tintColor
    self.isTranslucent = isTranslucent
  }
  
  public enum Shape {
    /// Rectangle with rounded corners
    case roundedRect
    
    /// Circular. Note this also looks half-decent when there's only a
    /// single button per toolbar.
    case circle
    
    /// No ornamentation
    case none
  }
  
  public let shape: Shape
  
  /// Custom tint colour. Uses default tint colour if set to `nil`
  public let tintColor: UIColor?
  
  public let isTranslucent: Bool
}

//
//  TGCardStyle.swift
//  TGCardViewController
//
//  Created by Adrian Schönig on 29.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public struct TGCardStyle {
  
  public static let `default` = TGCardStyle()

  /// @default Bold system font with size 17pt.
  public var titleFont: UIFont = .boldSystemFont(ofSize: 17)

  /// @default: Black
  public var titleTextColor: UIColor = .black

  /// @default Regular system font with size 15pt.
  public var subtitleFont: UIFont = .systemFont(ofSize: 15)

  /// @default: Light grey
  public var subtitleTextColor: UIColor = .lightGray

  /// @default: white
  public var backgroundColor: UIColor = .white

  /// @default: Grayscale @ 70%.
  public var grabHandleColor: UIColor = #colorLiteral(red: 0.7552321553, green: 0.7552321553, blue: 0.7552321553, alpha: 1)

}

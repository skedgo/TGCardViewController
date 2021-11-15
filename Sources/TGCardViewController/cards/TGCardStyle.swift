//
//  TGCardStyle.swift
//  TGCardViewController
//
//  Created by Adrian Schönig on 29.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

public struct TGCardStyle {
  
  public static let `default` = TGCardStyle()

  /// Font to use for title, defaults to bold system font with size 17pt.
  public var titleFont: UIFont = .boldSystemFont(ofSize: 17)

  /// Title colour, defaults to system label color
  public var titleTextColor: UIColor = .label

  /// Font to use for subtitles, defaults to system font with size 15pt.
  public var subtitleFont: UIFont = .systemFont(ofSize: 15)

  /// Colour for subtitles, defaults to secondary label color
  public var subtitleTextColor: UIColor = .secondaryLabel

  /// Colour to use for the background, defaults to system background color
  public var backgroundColor: UIColor = .systemBackground
  
  /// Colour to use for the grab handle on the card, defaults to system secondary label color
  public var grabHandleColor: UIColor = .secondaryLabel
  
  /// Colour for the cross is close button, defaults to system secondary label
  public var closeButtonCrossColor: UIColor = .secondaryLabel


  /// Colour for the close button's background, defaults to tertiary system grouped background
  public var closeButtonBackgroundColor: UIColor = .tertiarySystemGroupedBackground
  
}

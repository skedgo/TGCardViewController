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

  /// @default: System label color (iOS 13); black (up to iOS 12)
  public var titleTextColor: UIColor = {
    if #available(iOSApplicationExtension 13.0, *) {
      return .label
    } else {
      return .black
    }
  }()

  /// @default Regular system font with size 15pt.
  public var subtitleFont: UIFont = .systemFont(ofSize: 15)

  /// @default: System secondary label color (iOS 13); light grey (up to iOS 12)
  public var subtitleTextColor: UIColor = {
    if #available(iOSApplicationExtension 13.0, *) {
      return .secondaryLabel
    } else {
      return .lightGray
    }
  }()

  /// @default: System background color (iOS 13); white (up to iOS 12)
  public var backgroundColor: UIColor = {
    if #available(iOSApplicationExtension 13.0, *) {
      return .systemBackground
    } else {
      return .white
    }
  }()
  
  /// @default: System secondary label color (iOS 13); Grayscale @ 70% (up to iOS 12)
  public var grabHandleColor: UIColor = {
    if #available(iOSApplicationExtension 13.0, *) {
      return .secondaryLabel
    } else {
      return #colorLiteral(red: 0.7552321553, green: 0.7552321553, blue: 0.7552321553, alpha: 1)
    }
  }()

  /// @default: TripKitUI Black 5
  public var closeButtonBackgroundColor: UIColor = #colorLiteral(red: 0.13, green: 0.16, blue: 0.2, alpha: 0.08)
  
  public var closeButtonCrossColor: UIColor = #colorLiteral(red: 0.44, green: 0.46, blue: 0.48, alpha: 1.0)
}

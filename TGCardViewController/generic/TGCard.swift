//
//  TGCard.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

/// A card representing the content currently displayed
protocol TGCard {
  
  /// The card controller currently displaying the card
  ///
  /// Set by the card controller itself
  weak var controller: TGCardViewController? { get set }
  
  /// Localised title of the card
  var title: String { get }
  
  /// Localised optional subtitle of the card
  var subtitle: String? { get }
  
  /// The content to display on the card below title + subtitle
  ///
  /// Can be large as it will get embedded in a scroll view.
  /// Can have interactive elements.
  var contentView: UIView? { get }

  /// The manager that handles the content of the map for this card
  var mapManager: TGMapManager? { get }
  
  /// Builds the card view to represent the card
  ///
  /// - Returns: Card view configured with the content of this card
  func buildView(showClose: Bool) -> TGCardView
  
  /// Called just before the card becomes visible
  ///
  /// Called when card gets pushed onto a card
  /// controller, or the controller itself becomes
  /// visible.
  ///
  /// - Parameter animated: If it'll be animated
  func willAppear(animated: Bool)
  
  /// Called when the card became visible
  ///
  /// - seeAlso: Notes in `willAppear`
  ///
  /// - Parameter animated: If it was animated
  func didAppear(animated: Bool)
  
  /// Called just before the card disappears
  ///
  /// Called when card gets popped from a card
  /// controller, or the controller itself disappears.
  ///
  /// - Parameter animated: If it'll be animated
  func willDisappear(animated: Bool)
  
  /// Called when the card disappared
  ///
  /// - seeAlso: Notes in `willDisappear`
  ///
  /// - Parameter animated: If it was animated
  func didDisappear(animated: Bool)
}

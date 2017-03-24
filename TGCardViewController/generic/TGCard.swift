//
//  TGCard.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

/// A card representing the content currently displayed
///
/// Class-protocol as we'll dynamically set the `controller` and 
/// `delegate` fields.
protocol TGCard: class {
  
  /// The card controller currently displaying the card
  ///
  /// Set by the card controller itself
  weak var controller: TGCardViewController? { get set }
  
  weak var delegate: TGCardDelegate? { get set }
  
  /// Localised title of the card
  var title: String { get }
  
  /// The manager that handles the content of the map for this card
  var mapManager: TGMapManager? { get }
  
  /// The position to display the card in, when pushing
  var defaultPosition: TGCardPosition { get }
  
  /// Builds the card view to represent the card
  ///
  /// - Returns: Card view configured with the content of this card
  func buildCardView(showClose: Bool) -> TGCardView
  
  func buildHeaderView() -> TGHeaderView?
  
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

protocol TGCardDelegate: class {
  func mapManagerDidChange(old: TGMapManager?, for card: TGCard)
}

extension TGCard {
  
  func willAppear(animated: Bool) { }
  
  func didAppear(animated: Bool) { }
  
  func willDisappear(animated: Bool) { }
  
  func didDisappear(animated: Bool) { }
  
}

//
//  TGScrollCard.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 18/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TGScrollCard: TGCard {
  
  weak var controller: TGCardViewController? {
    didSet {
      contentCards.forEach {
        $0.controller = controller
      }
    }
  }
  
  weak var delegate: TGCardDelegate? = nil
  
  let title: String
  
  // Scroll card itself doesn't have a map manager. Instead, it passes through
  // the manager that handles the map view for the current card. This is
  // set on intialising and then updated whenever we scroll.
  var mapManager: TGMapManager? {
    didSet {
      delegate?.mapManagerDidChange(old: oldValue, for: self)
    }
  }
  
  let defaultPosition: TGCardPosition
  
  let contentCards: [TGCard]
  
  let initialPageIndex: Int
  
  var cardView: TGScrollCardView? = nil
  
  init(title: String, contentCards: [TGCard], initialPage: Int = 0, initialPosition: TGCardPosition = .peaking) {
    guard initialPage < contentCards.count else {
      preconditionFailure()
    }
    
    self.title = title
    self.contentCards = contentCards
    self.initialPageIndex = initialPage
    self.defaultPosition = initialPosition
    
    // Initialise map manager probably, then we'll wait for delegate
    // callbacks to update it correctly
    self.mapManager = contentCards[initialPage].mapManager
  }
  
  func buildView(showClose: Bool) -> TGCardView {
    let view = TGScrollCardView.instantiate()
    view.configure(with: self)
    view.delegate = self
    cardView = view
    return view
  }
  
  
  // MARK: - Navigation
  
  func moveForward() {
    cardView?.moveForward()
  }
  
  func moveBackward() {
    cardView?.moveBackward()
  }
  
  func move(to page: Int) {
    cardView?.move(to: page)
  }

  
  // MARK: - Card life cycle
  
  func didAppear(animated: Bool) {
    // Subclass to implement
  }
  
  func willAppear(animated: Bool) {
    // Subclass to implement
  }
  
  func willDisappear(animated: Bool) {
    // Subclass to implement
  }
  
  func didDisappear(animated: Bool) {
    // Subclass to implement
  }  
  
}

extension TGScrollCard: TGScrollCardViewDelegate {
  
  func didChangeCurrentPage(to index: Int) {
    guard index < contentCards.count else {
      assertionFailure()
      return
    }
    
    mapManager = contentCards[index].mapManager
  }
  
}

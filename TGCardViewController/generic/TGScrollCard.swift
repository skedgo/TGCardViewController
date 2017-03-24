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
  
  fileprivate var cardView: TGScrollCardView? = nil
  
  fileprivate lazy var headerView: TGHeaderView? = nil
  
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
  
  func buildCardView(showClose: Bool) -> TGCardView {
    let view = TGScrollCardView.instantiate()
    view.configure(with: self)
    view.delegate = self
    cardView = view
    return view
  }
  
  func buildHeaderView() -> TGHeaderView? {
    if let header = headerView {
      return header
    }
    
    let view = TGHeaderView.instantiate()
    let card = contentCards[initialPageIndex]
    headerView = view
    updateHeader(for: card, atIndex: initialPageIndex)
    return view
  }

  // MARK: - Header actions
  
  fileprivate func update(forCardAtIndex index: Int) {
    guard index < contentCards.count else {
      assertionFailure()
      return
    }
    
    let card = contentCards[index]
    
    mapManager = card.mapManager
    updateHeader(for: card, atIndex: index)
  }
  
  fileprivate func updateHeader(for card: TGCard, atIndex index: Int) {
    guard let headerView = headerView else {
      preconditionFailure()
    }
    
    headerView.titleLabel.text = card.title
    // headerView.subtitleLabel.text = card.subtitle
    
    if index + 1 < contentCards.count {
      headerView.rightAction = { [unowned self] in
        self.moveForward()
      }
    } else {
      headerView.rightAction = nil
    }
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
    update(forCardAtIndex: index)
  }
  
}

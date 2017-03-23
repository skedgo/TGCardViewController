//
//  TGScrollCard.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 18/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import RxSwift

class TGScrollCard: TGCard {
  
  weak var controller: TGCardViewController? {
    didSet {
      contentCards.forEach {
        // Since TGCard is not specified as a class-only protocol, $0 can be 
        // either a reference-type instance or a value-type instance. Hence,
        // compiler will issue a warning about $0 being immutable. Assigning
        // $0 to a variable allows us to modify its controller property.
        var vCard = $0
        vCard.controller = controller
      }
    }
  }
  
  let title: String
  
  // Scroll card itself doesn't have a map manager. Instead, it passes through
  // the manager that handles the map view for the current card.
  var mapManager: TGMapManager? {
    let currentPage = rx_currentPageIndex_var.value
    return contentCards[currentPage].mapManager
  }
  
  let defaultPosition: TGCardPosition
  
  let contentCards: [TGCard]
  
  let initialPageIndex: Int
  
  fileprivate let disposeBag = DisposeBag()
  
  fileprivate let rx_currentPageIndex_var: Variable<Int>
  var rx_currentPageIndex: Observable<Int> {
    return rx_currentPageIndex_var.asObservable()
  }
  
  init(title: String, contentCards: [TGCard], initialPage: Int = 0, initialPosition: TGCardPosition = .peaking) {
    self.title = title
    self.contentCards = contentCards
    self.initialPageIndex = initialPage
    self.defaultPosition = initialPosition
    self.rx_currentPageIndex_var = Variable(initialPage)
  }
  
  func buildView(showClose: Bool) -> TGCardView {
    let view = TGScrollCardView.instantiate()
    rx_currentPageIndex_var.value = initialPageIndex
    view.configure(with: self)
    return view
  }
  
  // MARK: - Navigation
  
  func moveForward() {
    let old = rx_currentPageIndex_var.value
    let new = min(old + 1, contentCards.count - 1)
    rx_currentPageIndex_var.value = new
  }
  
  func moveBackward() {
    let old = rx_currentPageIndex_var.value
    let new = max(old - 1, 0)
    rx_currentPageIndex_var.value = new
  }
  
  func move(to page: Int) {
    guard 0..<contentCards.count ~= page else { return }
    rx_currentPageIndex_var.value = page
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

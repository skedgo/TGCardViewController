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
  
  enum Direction {
    case forward
    case backward
    case jump(Int)
  }
  
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
  let mapManager: TGMapManager?
  let defaultPosition: TGCardPosition
  
  let contentCards: [TGCard]
  
  var move = PublishSubject<Direction>()
  
  init(title: String, contentCards: [TGCard], mapManager: TGMapManager? = nil) {
    self.title = title
    self.mapManager = mapManager
    self.contentCards = contentCards
    self.defaultPosition = mapManager != nil ? .peaking : .extended
  }
  
  func buildView(showClose: Bool) -> TGCardView {
    let view = TGScrollCardView.instantiate()
    
    // It's important that we use a new observable here. The observable
    // will be added to the disposable bag maintained by `view`. As that
    // view gets deallocated, so does the disposable bag and we will not
    // be getting any future events from the observable.
    move = PublishSubject<Direction>()
    
    view.configure(with: self)
    return view
  }
  
  func didAppear(animated: Bool) {
    // Subclass to implement
  }
  
  func willAppear(animated: Bool) {
    // Subclass to implement
  }
  
}

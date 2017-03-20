//
//  TGScrollCard.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 18/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TGScrollCard: NSObject, TGCard {
  
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
  
  weak var delegate: TGScrollCardDelegate?
  
  let title: String
  let mapManager: TGMapManager?
  let defaultPosition: TGCardPosition
  
  let contentCards: [TGCard]
  
  init(title: String, contentCards: [TGCard], mapManager: TGMapManager? = nil) {
    self.title = title
    self.mapManager = mapManager
    self.contentCards = contentCards
    self.defaultPosition = mapManager != nil ? .peaking : .extended
  }
  
  func buildView(showClose: Bool) -> TGCardView {
    let view = TGScrollCardView.instantiate()
    view.configure(with: self)
    view.scrollView.delegate = self
    return view
  }

}

protocol TGScrollCardDelegate: class {
  
  func scrollCardDidEndPaging(_ card: TGScrollCard)
  
}

extension TGScrollCard: UIScrollViewDelegate {
  
  func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
    scrollView.isUserInteractionEnabled = false
  }
  
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    scrollView.isUserInteractionEnabled = true
    delegate?.scrollCardDidEndPaging(self)
  }
  
}

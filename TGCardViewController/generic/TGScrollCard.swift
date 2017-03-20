//
//  TGScrollCard.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 18/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TGScrollCard: TGCard {
  
  weak var controller: TGCardViewController?
  
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
    return view
  }

}

//
//  TGPagingCard.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 16/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TGPagingPlainCard: TGCard {
  weak var controller: TGCardViewController?
  
  let title: String
  let subtitle: String?
  let mapManager: TGMapManager?
  let contentViews: [UIView]
  
  init(title: String, subtitle: String?, contentViews: [UIView] = [], mapManager: TGMapManager?) {
    self.title = title
    self.subtitle = subtitle
    self.contentViews = contentViews
    self.mapManager = mapManager
  }
  
  func buildView(showClose: Bool) -> TGCardView {
    let view = TGPagingPlainCardView.instantiate()
    view.configure(with: self, dismissable: showClose)
    return view
  }
  
  // MARK: - Card view life cycle
  
  func willAppear(animated: Bool) { }
  
  func didAppear(animated: Bool) { }
  
  func willDisappear(animated: Bool) { }
  
  func didDisappear(animated: Bool) { }
  
  
}

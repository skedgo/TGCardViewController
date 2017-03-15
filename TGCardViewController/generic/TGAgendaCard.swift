//
//  TGAgendacard.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 16/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TGAgendaCard: TGTableCard {
  
  override func buildView(showClose: Bool) -> TGCardView {
    let view = TGAgendaCardView.newInstance()
    view.configure(with: self, showClose: showClose)
    return view
  }

}

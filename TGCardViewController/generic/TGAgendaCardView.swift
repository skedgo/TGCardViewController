//
//  TGAgendaCardView.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 15/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TGAgendaCardView: TGTableCardView {

  @IBOutlet weak var bottomViewContainer: UIView!
  @IBOutlet weak var bottomViewContainerHeightConstraint: NSLayoutConstraint!
  
  static func newInstance() -> TGAgendaCardView {
    let bundle = Bundle(for: self)
    return bundle.loadNibNamed("TGAgendaCardView", owner: nil, options: nil)!.first as! TGAgendaCardView
  }
  
  override func configure(with card: TGTableCard, showClose: Bool) {
    super.configure(with: card, showClose: showClose)
    
    if let _ = card as? TGAgendaCard {
      // agenda specific configuration
    }
  }
}

//
//  TurnByTurnHeaderView.swift
//  Example
//
//  Created by Adrian Schönig on 06.04.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TGCardViewController

class TurnByTurnHeaderView: TGHeaderView {
  
  @IBOutlet weak var backgroundView: UIView!
  
  override var cornerRadius: CGFloat {
    didSet {
      self.backgroundView.layer.cornerRadius = cornerRadius
    }
  }
  
  static func newInstance() -> TurnByTurnHeaderView {
    return Bundle(for: self).loadNibNamed("TurnByTurnHeaderView", owner: nil, options: nil)!.first as! TurnByTurnHeaderView
  }


}

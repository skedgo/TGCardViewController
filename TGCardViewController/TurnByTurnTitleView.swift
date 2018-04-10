//
//  TurnByTurnTitleView.swift
//  Example
//
//  Created by Kuan Lun Huang on 10/4/18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TurnByTurnTitleView: UIView {
  
  static func newInstance() -> TurnByTurnTitleView {
    let bundle = Bundle(for: self)
    return bundle.loadNibNamed("TurnByTurnTitleView", owner: self, options: nil)?.first as! TurnByTurnTitleView
  }

}

//
//  TGCard.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

protocol TGCard {
  var title: String { get }
  var subtitle: String? { get }
  
  var contentView: UIView? { get }
  
  func buildView() -> UIView
}

//
//  TGCardPosition.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 15/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public enum TGCardPosition {
  /// Showing full card, with small bit of map on top
  case extended
  
  /// Showing card and map, each about half
  case peaking
  
  /// Showing only title of card
  case collapsed
}

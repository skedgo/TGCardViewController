//
//  TGNoCard.swift
//  TGCardViewController
//
//  Created by Adrian Schönig on 29.03.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

/// This "card" let's you display map content without a card, through the map manager.
open class TGNoCard: TGCard {
  
  public init(title: String, mapManager: TGCompatibleMapManager) {
    super.init(
      title: .default(title, nil, nil),
      mapManager: mapManager,
      initialPosition: .collapsed
    )
  }
  
  public override func buildCardView() -> TGCardView? {
    return nil
  }
}

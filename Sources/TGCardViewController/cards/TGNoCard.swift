//
//  TGNoCard.swift
//  TGCardViewController
//
//  Created by Adrian Schönig on 29.03.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

/// This "card" let's you display map content without a card, through the map manager.
public final class TGNoCard: TGCard {
  
  public init(title: String, mapManager: TGCompatibleMapManager) {
    super.init(
      title: .default(title, nil, nil),
      mapManager: mapManager,
      initialPosition: .collapsed
    )
  }
  
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  public override func encode(with aCoder: NSCoder) {
    super.encode(with: aCoder)
  }
  
  public override func buildCardView() -> TGCardView? {
    return nil
  }
}

//
//  ExampleScrollCard.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 20/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class ExampleScrollCard: TGScrollCard {
  
  init() {
    let card1 = TGPlainCard(title: "Sample card 1")
    
    let card2 = ExampleTableCard()
    
    let card3 = ExampleChildCard()
    
    super.init(title: "Paging views", contentCards: [card1, card2, card3])
  }
  
}

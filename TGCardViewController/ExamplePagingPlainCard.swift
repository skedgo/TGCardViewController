//
//  ExamplePagingPlainCard.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 16/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class ExamplePagingPlainCard: TGPagingPlainCard {
  
  init() {
    let page1 = UIView()
    page1.backgroundColor = .green
    
    let page2 = UIView()
    page2.backgroundColor = .yellow
    
    let page3 = UIView()
    page3.backgroundColor = .blue
    
    let pages = [page1, page2]
    
    super.init(title: "Pager w/o table", subtitle: nil, contentViews: pages, mapManager: nil)
  }

}

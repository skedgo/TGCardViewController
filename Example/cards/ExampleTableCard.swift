//
//  ExampleTableCard.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 10/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import SwiftUI
import UIKit

import TGCardViewController

class ExampleTableCard : TGTableCard {

  private let source = ExampleTableDataSource()
  
  private var pushOnTap: Bool

  init(pushOnTap: Bool = true) {
    
    let mapManager = ExampleMapManager()
    mapManager.annotations = source.stops

    self.pushOnTap = pushOnTap

    super.init(
      title: .customExtended(TableTitle()),
      dataSource: source,
      delegate: source,
      mapManager: mapManager
    )
    
    handleMacSelection = source.handleSelection
    bottomMapToolBarItems = [UIButton.dummyDetailDisclosureButton()]
  }
  
  override func didBuild(tableView: UITableView) {
    super.didBuild(tableView: tableView)

    tableView.dragInteractionEnabled = true
    
    let topSpacer = UIView(frame: .init(x: 0, y: 0, width: 100, height: 100))
    tableView.tableHeaderView = topSpacer
    
    if pushOnTap {
      source.onSelect = {
        let card = ExampleTableChildCard(annotation: $0)
        self.controller?.push(card, animated: true)
      }
    } else {
      source.onSelect = {
        let annotation = $0
        (self.mapManager as? ExampleMapManager)?.setCenter(annotation.coordinate, animated: true)
      }
    }
  }
  
}

struct TableTitle: View {
  
  var body: some View {
    HStack {
      Text("London Stops")
        .font(.largeTitle)
    }
  }
  
}

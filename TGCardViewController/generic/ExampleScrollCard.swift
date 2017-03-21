//
//  ExampleScrollCard.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 20/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import MapKit
import RxCocoa
import RxSwift

class ExampleScrollCard: TGScrollCard {
  
  fileprivate let disposeBag = DisposeBag()
  
  init() {
    let card1 = TGPlainCard(title: "Sample card 1")
    let card2 = ExampleTableCard()
    let card3 = ExampleChildCard()
    
    let sydney = MKPointAnnotation()
    sydney.coordinate = CLLocationCoordinate2DMake(-33.86, 151.21)
    
    let mapManager = TGMapManager()
    mapManager.annotations = [sydney]
    mapManager.preferredZoomLevel = .city
    
    super.init(title: "Paging views", contentCards: [card1, card2, card3], mapManager: mapManager)
  }
  
  override func willAppear(animated: Bool) {
    super.willAppear(animated: animated)
    showHeaderView()
  }
  
  
  fileprivate func showHeaderView() {
    let headerView = ExampleScrollStickyView.instantiate()
    
    headerView.closeButton.rx.tap
      .subscribe(onNext: { [weak self] in
        self?.controller?.pop()
        self?.controller?.hideStickyBar(animated: true)
      })
      .addDisposableTo(disposeBag)
    
    headerView.nextButton.rx.tap
      .map { Direction.forward }
      .bindTo(move)
      .addDisposableTo(disposeBag)

    headerView.previousButton.rx.tap
      .map { Direction.backward }
      .bindTo(move)
      .addDisposableTo(disposeBag)
    
    controller?.showStickyBar(content: headerView, animated: true)
  }
  
}

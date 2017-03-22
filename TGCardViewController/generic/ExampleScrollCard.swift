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
    let card4 = TGPlainCard(title: "Sample card 4")
    let card5 = TGPlainCard(title: "Sample card 5")
    super.init(title: "Paging views", contentCards: [card1, card2, card3, card4, card5])
  }
  
  override func willAppear(animated: Bool) {
    super.willAppear(animated: animated)
    showHeaderView()
  }
  
  override func willDisappear(animated: Bool) {
    super.willDisappear(animated: animated)
    controller?.hideStickyBar(animated: true)
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
      .subscribe(onNext: { self.moveForward() })
      .addDisposableTo(disposeBag)
    
    headerView.previousButton.rx.tap
      .subscribe(onNext: { self.moveBackward() })
      .addDisposableTo(disposeBag)
    
    headerView.jumpButton.rx.tap
      .map {
        let index = arc4random_uniform(UInt32(self.contentCards.count))
        return Int(index)
      }
      .subscribe(onNext: { self.move(to: $0) })
      .addDisposableTo(disposeBag)
    
    controller?.showStickyBar(content: headerView, animated: true)
  }
  
}

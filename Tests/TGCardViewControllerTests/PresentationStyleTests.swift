//
//  PresentationStyleTests.swift
//  TGCardViewControllerTests
//
//  Created by Adrian Schoenig on 14/11/2026.
//  Copyright © 2026 SkedGo Pty Ltd. All rights reserved.
//

import Testing
import UIKit

@testable import TGCardViewController

@MainActor
@Suite(.serialized)
struct PresentationStyleTests {

  // MARK: - Choosing between sheet and embedded cards

  @Test func automaticWantsSystemSheetOnIOS27() {
    let controller = makeCardController()

    if #available(iOS 27.0, *) {
      #expect(controller.wantsSystemSheet)
    } else {
      #expect(!controller.wantsSystemSheet)
    }
  }

  @Test func embeddedNeverWantsSystemSheet() {
    let controller = makeCardController()
    controller.presentationStyle = .embedded

    #expect(!controller.wantsSystemSheet)
  }

  // MARK: - On screen

  @Test func automaticShowsCardsInSystemSheetOnIOS27() async throws {
    let controller = makeCardController()
    let window = show(controller)
    defer { window.isHidden = true }
    try await settle()

    if #available(iOS 27.0, *) {
      #expect(controller.usesSystemSheet)
      #expect(controller.presentedViewController != nil)
    } else {
      #expect(!controller.usesSystemSheet)
    }
  }

  @Test func embeddedShowsCardsInOwnViewInsideTab() async throws {
    let controller = makeCardController()
    controller.presentationStyle = .embedded
    let tabs = UITabBarController()
    tabs.viewControllers = [controller, UIViewController()]
    let window = show(tabs)
    defer { window.isHidden = true }
    try await settle()

    // Nothing is presented, as that would cover the tab bar
    #expect(!controller.usesSystemSheet)
    #expect(controller.presentedViewController == nil)
    #expect(tabs.presentedViewController == nil)

    // The cards are visible, in the controller's own view
    #expect(controller.cardWrapperContent.isDescendant(of: controller.view))
    #expect(controller.cardWrapperShadow.alpha == 1)
    #expect(!controller.cardWrapperShadow.isHidden)
  }

  @Test func embeddedCollapsedCardKeepsTitleAboveTabBar() async throws {
    let controller = makeCardController()
    controller.presentationStyle = .embedded
    let tabs = UITabBarController()
    tabs.viewControllers = [controller, UIViewController()]
    let window = show(tabs)
    defer { window.isHidden = true }
    try await settle()

    #expect(controller.cardPosition == .collapsed)

    let cardView = try #require(controller.topCardView)
    let titleHeight = cardView.headerHeight(for: .collapsed)
    #expect(titleHeight > 0)

    let cardTop = controller.cardWrapperShadow.convert(controller.cardWrapperShadow.bounds, to: window).minY
    let tabBarTop = tabs.tabBar.convert(tabs.tabBar.bounds, to: window).minY
    #expect(tabBarTop < window.bounds.height)
    #expect(cardTop + titleHeight <= tabBarTop + 0.5)
  }

  // MARK: - Helpers

  private func makeCardController() -> TGCardViewController {
    let controller = TGCardViewController(nibName: "TGCardViewController", bundle: TGCardViewController.bundle)
    controller.rootCard = TGPlainCard(
      title: "Title",
      subtitle: "Subtitle",
      contentView: UIView(),
      mapManager: TGMapManager(),
      initialPosition: .collapsed
    )
    return controller
  }

  private func show(_ root: UIViewController) -> UIWindow {
    let window: UIWindow
    if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
      window = UIWindow(windowScene: scene)
    } else {
      window = UIWindow(frame: UIScreen.main.bounds)
    }
    window.rootViewController = root
    window.makeKeyAndVisible()
    window.layoutIfNeeded()
    return window
  }

  /// The initial cards get pushed on the first layout, and a sheet only gets
  /// presented once the controller appeared
  private func settle() async throws {
    try await Task.sleep(for: .milliseconds(750))
  }

}

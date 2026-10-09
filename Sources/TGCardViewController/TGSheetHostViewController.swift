//
//  TGSheetHostViewController.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/10/2026.
//  Copyright © 2026 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

/// Hosts the card stack in a system sheet, when ``TGCardViewController`` presents
/// its cards using ``TGCardViewController/PresentationStyle-swift.enum/systemSheet``.
///
/// The card controller stays in charge of the cards, the map and the header. This
/// controller only provides the sheet's view, forwards the sheet's callbacks, and
/// makes sure that only the card controller can dismiss the sheet. Presentations
/// and dismissals that reach this controller are routed back through the card
/// controller, so that subclasses overriding `present` or `dismiss` on the card
/// controller see them, too.
@MainActor
final class TGSheetHostViewController: UIViewController {

  private(set) weak var cardController: TGCardViewController?

  /// Set by the card controller while it dismisses the sheet itself.
  var allowsDismissingSheet = false
  
  /// Whether something presented on top of the sheet covers the screen
  private var isCoveredByPresentation = false

  init(cardController: TGCardViewController) {
    self.cardController = cardController
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .pageSheet
    isModalInPresentation = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    let view = UIView()
    view.backgroundColor = .clear
    view.clipsToBounds = true
    if #available(iOS 26.0, *) {
      // The sheet rounds its background but doesn't clip what's in it, so cards
      // with opaque content would stick out at its corners.
      view.cornerConfiguration = .corners(radius: .containerConcentric())
    }
    self.view = view
  }

  // The card controller is the presenting view controller, but make that explicit,
  // so that anything in the sheet that isn't part of a card's own responder chain
  // still reaches the card controller's key commands and actions.
  override var next: UIResponder? {
    cardController ?? super.next
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    if #available(iOS 27.1, *) {
      // The close button follows the vertical bar, e.g., when folding an
      // iPhone Duo
      registerForTraitChanges(UITraitCollection.systemTraitsAffectingVerticalBarEdge) { (host: TGSheetHostViewController, _: UITraitCollection) in
        host.cardController?.updateSheetBarItems()
      }
    }
  }
  
  // MARK: - Appearance
  
  // Something presented full screen on top of the sheet would have made the card
  // controller disappear, if it had presented it itself. Tell it, so that it, its
  // subclasses and its cards get the same callbacks with and without the sheet.
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    if presentedViewController != nil, !isBeingDismissed, let cardController {
      isCoveredByPresentation = true
      cardController.beginAppearanceTransition(false, animated: animated)
    }
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    if isCoveredByPresentation {
      cardController?.endAppearanceTransition()
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if isCoveredByPresentation {
      cardController?.beginAppearanceTransition(true, animated: animated)
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    if isCoveredByPresentation {
      isCoveredByPresentation = false
      cardController?.endAppearanceTransition()
    }
    
    // Only now is it in its final place, which determines the vertical bar
    cardController?.updateSheetBarItems()
  }
  
  // MARK: - Layout
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    cardController?.sheetHostDidLayoutSubviews()
  }

  override func accessibilityPerformEscape() -> Bool {
    cardController?.popMaybe() ?? false
  }

  // MARK: - Presenting and dismissing

  override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
    if let cardController {
      // Ends up in `presentDirectly` via the card controller's routing
      cardController.present(viewControllerToPresent, animated: flag, completion: completion)
    } else {
      super.present(viewControllerToPresent, animated: flag, completion: completion)
    }
  }

  override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
    if allowsDismissingSheet {
      super.dismiss(animated: flag, completion: completion)
    } else if let cardController {
      // Ends up in `dismissPresented` via the card controller's routing
      cardController.dismiss(animated: flag, completion: completion)
    } else {
      super.dismiss(animated: flag, completion: completion)
    }
  }

  /// Presents on top of the sheet, without routing through the card controller.
  func presentDirectly(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
    super.present(viewControllerToPresent, animated: flag, completion: completion)
  }

  /// Dismisses whatever is presented on top of the sheet, but never the sheet itself.
  func dismissPresented(animated flag: Bool, completion: (() -> Void)?) {
    guard presentedViewController != nil else {
      completion?()
      return
    }
    super.dismiss(animated: flag, completion: completion)
  }

}

// MARK: - UISheetPresentationControllerDelegate

extension TGSheetHostViewController: UISheetPresentationControllerDelegate {

  func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
    cardController?.sheetDidChangeSelectedDetent()
  }

  func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
    false
  }

}

//
//  TGCardViewController.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//
// 
// Exception for this file. Already broken into extensions.
// swiftlint:disable file_length
// swiftlint:disable type_body_length

import UIKit

import MapKit

@MainActor
public protocol TGCardViewControllerDelegate: AnyObject {
  func requestsDismissal(for controller: TGCardViewController)
}

/// The root view controller for using cards in your app.
///
/// A single view controller that'll manages a single map view (which can be from MapKit or any other
/// mapping framework) and stack of cards (see ``TGCard``). The cards can have a map manager, and
/// pushing and popping cards will pass the map view to the card's map manager (see ``TGCompatibleMapManager``).
///
/// ## How to use this in your app
///
/// First, create a subclass, then use this in your your storyboard.
///
/// Second, In your subclass override `init(coder:)` as follows, so that the
/// instance from the storyboard isn’t used, but instead the pre-configured one
/// from `TGCardViewController.xib`:
///
/// ```swift
/// import TGCardViewController
///
/// class CardViewController: TGCardViewController {
///
///   required init(coder aDecoder: NSCoder) {
///     // When loading from the storyboard we don't want to use the controller
///     // as defined in the storyboard but instead use the TGCardViewController.xib
///     super.init(nibName: "TGCardViewController", bundle: TGCardViewController.bundle)
///   }
///
///   ...
/// }
/// ```
///
/// Third, and last, create a `TGCard` that represents the card at the top
/// level, and add then set that in your view controller’s `viewDidLoad`:
///
/// ```swift
/// override func viewDidLoad() {
///   rootCard = MyRootCard()
///   super.viewDidLoad()
/// }
/// ```
///
/// ### State restoration
///
/// This class supports state restoration, which re-creates the hierarchy of
/// cards. Cards are restored using `NSCoding`, so if you want to use state
/// restoration in your app, make sure to override the `init(coder:)` and
/// `encode(with:)` methods.
///
/// If you don't want to restore a particular card instance, just return `nil`
/// from `init(coder:)`. Only the card hierarchy up to before that card will
/// then be restored.
///
/// Two basic approaches exist for the state restoration of cards:
///
/// 1. Use the basic built-in support and call `super`. This takes care of the
///    basic card content and views, but check the card documentation for
///    details. Note that map managers, delegates and data source will *not*
///    be restored this way.
/// 2. Do it yourself by not calling `super` and using convenience initialisers
///    for `init(coder:)`. The typical approach here is to save and restore the
///    basic information, to then call your usual `init` methods on the cards.
@MainActor
open class TGCardViewController: UIViewController {
  
  enum Constants {
    /// The minimum number of points between the status bar and the
    /// top of the card to keep a bit of the map always showing through.
    fileprivate static let minMapSpace: CGFloat = 50
    
    fileprivate static let minMapSpaceWithHomeIndicator: CGFloat = 12
    
    static let minCardHeightWhenCollapsed: CGFloat = 44 * 0.66
    
    fileprivate static let pushAnimationDuration = 0.25

    /// The minimum seconds for snapping after the user panned the top card.
    /// Good to be a little higher than others as it'll spring.
    fileprivate static let snapAnimationMinimumDuration = 0.4

    /// The seconds for switching the top card to its new location after tapping it.
    static let tapAnimationDuration = 0.25

    fileprivate static let mapShadowVisibleAlpha: CGFloat = 0.25

    fileprivate static let floatingHeaderTopMargin: CGFloat = 20

    fileprivate static let iOS26CornerRadius: CGFloat = 32

    /// The space between the header and a system sheet, when the sheet is extended.
    static let sheetSpacingBelowHeader: CGFloat = 8
    
    /// The tallest a collapsed sheet can be while it still floats above the
    /// bottom edge, rather than attaching to it with the bottom safe area added
    /// below the content. Observed on iOS 26 for custom detents.
    static let sheetMaximumFloatingHeight: CGFloat = 100
    
    /// Pushing and popping cross-fade between cards in a system sheet
    static let sheetCrossFadeDuration = 0.25
  }
  
  public enum Mode {
    /// The default style with a floating cards, either at the bottom of the screen or on the left, depending
    /// on the size of the view. This mode supports all the features.
    case floating
    
    /// An alternative style intended for use on macOS. Styles the cards to be in a sidebar on the left
    /// with a vibrant transparency style. The sidebar is fixed and the various gestures from the `floating`
    /// style are disabled.
    case sidebar
  }
  
  #if SWIFT_PACKAGE
  public static var bundle = Bundle.module
  #else
  public static var bundle = Bundle(for: TGCardViewController.self)
  #endif
  
  open weak var delegate: TGCardViewControllerDelegate?
  
  /// The mode to use for the cards, either floating or as a sidebar. Can only be set on start.
  ///
  /// - Warning: Set before `viewDidLoad` is called. Changes afterwards are ignored.
  public var mode: Mode = {
    #if targetEnvironment(macCatalyst)
    return .sidebar
    #else
    return .floating
    #endif
  }()
  
  /// How the cards are presented: positioned by this controller itself, or in a
  /// system sheet. Defaults to ``PresentationStyle-swift.enum/automatic``, which
  /// uses system sheets on iOS 26+ where they fit. Check ``usesSystemSheet`` for
  /// what's currently used.
  ///
  /// - Warning: Set before `viewDidLoad` is called.
  public var presentationStyle: PresentationStyle = .automatic
  
  // MARK: System sheet state, see `TGCardViewController+SystemSheet.swift`
  
  /// Hosts the cards while they're shown in a system sheet
  var sheetHost: TGSheetHostViewController?
  var sheetContentHeightConstraint: NSLayoutConstraint?
  var savedCardContentConstraints: [NSLayoutConstraint] = []
  var savedCardWrapperEffect: UIVisualEffect?
  var sheetDetentValues: [TGCardPosition: CGFloat] = [:]
  var sheetTargetPosition: TGCardPosition?
  var isSheetDraggingEnabled = true
  
  /// Set while the initial cards wait for the sheet, so that they don't flash up
  /// in the classic presentation first
  var isAwaitingSystemSheet = false
  
  /// Set while pushing or popping, which update the sheet in one go
  var isTransitioningCards = false
  
  /// The top card's close button and bar actions, placed in the vertical bar
  /// on devices that have one, e.g., iPhone Duo. This one is over the map...
  var mapBarItems: TGBarItemsView?
  
  /// Shows the top card's `expandedBackgroundColor` across the whole sheet,
  /// including below a vertical bar, where the cards themselves don't go
  var sheetBackgroundView: UIView?
  
  /// ... and this one is on the sheet, for when that covers the vertical bar.
  var sheetBarItems: TGBarItemsView?
  
  var barItemsEdge: NSDirectionalRectEdge?
  
  /// The close buttons in the titles of the top card, hidden while the bar
  /// items stand in for them
  var suppressedCloseButtons: [UIButton] = []
  
  /// A Boolean value that specifies whether the close buttons
  /// on cards and headers are participating in spring-loaded
  /// interaction for a drag and drop activity.
  ///
  /// - Note: Only has an impact on iOS 11+
  public var navigationButtonsAreSpringLoaded: Bool = false
  
  public var headerBackgroundColor: UIColor? {
    get {
      return headerView.backgroundColor
    }
    set {
      headerView.backgroundColor = newValue
    }
  }
  
  @IBOutlet weak var headerEffectView: UIVisualEffectView!
  @IBOutlet weak var headerView: UIView!
  @IBOutlet weak var mapViewWrapper: UIView!
  @IBOutlet weak var mapShadow: UIView!
  @IBOutlet weak var cardWrapperShadow: UIView!
  @IBOutlet public weak var cardWrapperContent: UIView!
  @IBOutlet weak var cardWrapperEffectView: UIVisualEffectView!
  fileprivate weak var cardTransitionShadow: UIView?
  @IBOutlet weak var statusBarBlurView: UIVisualEffectView!
  @IBOutlet weak var topFloatingView: UIStackView!
  @IBOutlet weak var bottomFloatingView: UIStackView!
  @IBOutlet weak var topFloatingViewWrapper: UIVisualEffectView!
  @IBOutlet weak var bottomFloatingViewWrapper: UIVisualEffectView!
  @IBOutlet weak var sidebarBackground: UIView!
  @IBOutlet weak var sidebarVisualEffectView: UIVisualEffectView!
  @IBOutlet weak var sidebarSeparator: UIView!
  @IBOutlet weak var topInfoViewWrapper: UIView!
  
  // Positioning the cards
  @IBOutlet weak var cardWrapperDesiredTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var cardWrapperMinOverlapTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var cardWrapperHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var cardWrapperDynamicLeadingConstraint: NSLayoutConstraint!
  @IBOutlet weak var cardWrapperStaticLeadingConstraint: NSLayoutConstraint!
  
  // Positioning the header view
  @IBOutlet weak var headerViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var headerViewTopConstraint: NSLayoutConstraint!
  
  // Positioning the floating views.
  @IBOutlet weak var topFloatingViewTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var topFloatingViewTrailingToSafeAreaConstraint: NSLayoutConstraint!
  @IBOutlet weak var bottomFloatingViewTrailingToSafeAreaConstraint: NSLayoutConstraint!
  @IBOutlet weak var bottomFloatingViewBottomConstraint: NSLayoutConstraint! // only active in landscape
  
  // Dynamic constraints
  @IBOutlet weak var statusBarBlurHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var topInfoViewWrapperCenterXConstraint: NSLayoutConstraint!
  
  var mapViewController = TGMapViewController()
  public var mapView: UIView! { mapViewController.mapView }
  
  var panner: UIPanGestureRecognizer!
  var cardTapper: UITapGestureRecognizer!
  var mapShadowTapper: UITapGestureRecognizer!
#if !os(visionOS)
  var edgePanner: UIScreenEdgePanGestureRecognizer!
#endif
  
  /// Builder that determines what kind of map to use. The builder's
  /// `buildMapView` method will be once initially, and the map instance will
  /// then be passed to the card's `mapManager` via the
  /// `takeCharge(of:edgePadding:animated:)` and `cleanUp(_:animated:)` calls.
  ///
  /// Defaults to an instance of ``TGMapKitBuilder``, i.e., using Apple's MapKit.
  public var builder: TGCompatibleMapBuilder {
    get { mapViewController.builder }
    set { mapViewController.builder = newValue }
  }
  
  /// The card to display at the root. If you have more than one, use `initialCards`
  public var rootCard: TGCard? {
    get { initialCards.first }
    set { initialCards = [newValue].compactMap { $0 } }
  }

  /// The initial card stack to display
  public var initialCards: [TGCard] = []
  
  private var didAddInitialCards = false
  
  /// The style that's applied to the cards' top and bottom map tool
  /// bar items.
  ///
  /// Defaults to an empty ``TGButtonStyle``.
  public var buttonStyle: TGButtonStyle = .init() {
    didSet { applyToolbarItemStyle() }
  }

  /// Toggle for the default current location and compass buttons.
  ///
  /// - warning: Needs to be set **before** first loading the view controller's view.
  ///
  /// @default: `true`
  public var showDefaultButtons: Bool = true
  
  /// Position of current location and compass buttons
  ///
  /// Only used if `showDefaultButtons` is set to `true`.
  ///
  /// @default: `top`
  public var locationButtonPosition: TGButtonPosition = .top
  
  private var defaultButtons: [UIView]!

  /// Horizontal stack hosting the top card's `floatingCardToolBarItems`. Added
  /// to the controller's view (not the card), pinned to the bottom of the
  /// card's visible area and clamped to the safe area so it stays on screen.
  lazy var cardFloatingView: UIStackView = {
    let stack = UIStackView()
    stack.axis = .horizontal
    stack.spacing = 8
    stack.alignment = .center
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.isHidden = true
    return stack
  }()

  /// Swappable position constraints for `cardFloatingView`, toggled by
  /// `applyCardFloatingAlignment(_:)` per the top card's alignment.
  private var cardFloatingCenterXConstraint: NSLayoutConstraint?
  private var cardFloatingLeadingConstraint: NSLayoutConstraint?
  private var cardFloatingTrailingConstraint: NSLayoutConstraint?

  /// Views to overlay on the top-right of the map *for every card*, in addition
  /// to whatever each card's own `topMapToolBarItems` specifies. Use this for
  /// controls that should be reachable from any screen — a profile button, a
  /// global assistant entry point, etc.
  ///
  /// Items are arranged vertically. Per-card items (from `TGCard.topMapToolBarItems`)
  /// appear *below* these persistent ones in the same column.
  ///
  /// - SeeAlso: `persistentBottomMapToolBarItems`
  public var persistentTopMapToolBarItems: [UIView] = [] {
    didSet { if isViewLoaded, defaultButtons != nil { updateMapToolbarItems() } }
  }

  /// Bottom-right counterpart of `persistentTopMapToolBarItems`. Items here are
  /// arranged horizontally; per-card `bottomMapToolBarItems` appear to the right.
  public var persistentBottomMapToolBarItems: [UIView] = [] {
    didSet { if isViewLoaded, defaultButtons != nil { updateMapToolbarItems() } }
  }

  var allowFloatingViews: Bool = true
  
  public var draggingCardEnabled: Bool {
    get {
      usesSystemSheet ? isSheetDraggingEnabled : panner.isEnabled
    }
    set {
      isSheetDraggingEnabled = newValue
      if usesSystemSheet {
        // Pins the sheet to where it is or is going
        applySheetPosition(animated: true)
      } else {
        panner.isEnabled = newValue
      }
    }
  }

  /// This is just for debugging issues where it helps to disable
  /// everything related to panning. Otherwise it should always
  /// be set to `true`.
  private let panningAllowed = true
  
  private var isDraggingCard = false
  
  var isVisible = false
  
  /// To stop popping too quickly which messes things up
  private var isPopping = false
  
  fileprivate var previousCardPosition: TGCardPosition?
  
  var cards = [(card: TGCard, lastPosition: TGCardPosition, view: TGCardView?)]()

  // Before pushing a header that extends to the top
  private var previousStatusBarStyle: UIStatusBarStyle?
  private var headerStatusBarStyle: UIStatusBarStyle?

  // MARK: - UIViewController
  
  @MainActor
  open override func awakeFromNib() {
    super.awakeFromNib()
    
    self.restorationIdentifier = "CardViewController"
  }
  
  open override var preferredStatusBarStyle: UIStatusBarStyle {
    return headerStatusBarStyle ?? previousStatusBarStyle ?? .default
  }
  
  override open func viewDidLoad() {
    super.viewDidLoad()
    
    if #available(iOS 26.0, *) {
      statusBarBlurView.isHidden = true
    }
    
    // mode-specific styling
    TGCornerView.roundedCorners                   = mode == .floating
    cardWrapperDynamicLeadingConstraint.isActive  = mode == .floating
    cardWrapperStaticLeadingConstraint.isActive   = mode == .sidebar
    toggleCardWrappers(hide: true)
    
    sidebarSeparator.backgroundColor = .separator
    sidebarVisualEffectView.effect = UIBlurEffect(style: .systemThickMaterial)
    
    addChild(mapViewController)
    let mapView: UIView! = mapViewController.view
    mapViewWrapper.addSubview(mapView)
    mapView.topAnchor.constraint(equalTo: mapViewWrapper.topAnchor).isActive = true
    mapView.trailingAnchor.constraint(equalTo: mapViewWrapper.trailingAnchor).isActive = true
    mapView.bottomAnchor.constraint(equalTo: mapViewWrapper.bottomAnchor).isActive = true
    mapView.leadingAnchor.constraint(equalTo: mapViewWrapper.leadingAnchor).isActive = true
    mapView.translatesAutoresizingMaskIntoConstraints = false
    mapViewController.didMove(toParent: self)

    if #available(iOS 26.0, visionOS 26.0, *) {
#if os(visionOS)
      cardWrapperEffectView.effect = UIBlurEffect(style: .regular)
      headerEffectView.effect = UIBlurEffect(style: .regular)
#else
      cardWrapperEffectView.effect = UIGlassEffect(style: .regular)
      headerEffectView.effect = UIGlassEffect(style: .regular)
#endif
      cardWrapperEffectView.cornerConfiguration = .corners(radius: UICornerRadius.fixed(Constants.iOS26CornerRadius))

      headerEffectView.cornerConfiguration = .corners(
        topLeftRadius: nil,
        topRightRadius: nil,
        bottomLeftRadius: UICornerRadius.fixed(Constants.iOS26CornerRadius),
        bottomRightRadius: UICornerRadius.fixed(Constants.iOS26CornerRadius)
      )
    } else {
      cardWrapperEffectView.effect = nil
      headerEffectView.effect = nil
    }
    
    setupGestures()
    
    // Create the default buttons
    if showDefaultButtons {
      defaultButtons = [
          builder.buildUserTrackingButton(for: mapView),
          builder.buildCompassButton(for: mapView)
        ].compactMap { $0 }
    } else {
      defaultButtons = []
    }
    
    // Setting up additional constraints
    cardWrapperHeightConstraint.constant = extendedMinY * -1
    cardWrapperMinOverlapTopConstraint.constant = 0
    
    // Hide the bars at first
    hideHeader(animated: false)
    
    // Hide the top info view first
    hideInfoView(animated: false)

    // Collapse card at first
    mapViewController.additionalSafeAreaInsets = updateCardPosition(y: collapsedMinY)
    
    // Add a bit of a shadow behind card.
    if mode == .floating, #unavailable(iOS 26.0) {
      cardWrapperShadow.layer.shadowColor = UIColor.black.cgColor
      cardWrapperShadow.layer.shadowOffset = .init(width: 0, height: 2)
      cardWrapperShadow.layer.shadowRadius = 4
      cardWrapperShadow.layer.shadowOpacity = 0.16
    }
    
    monitorVoiceOverStatus()
  }

  /// Lazily adds `cardFloatingView` and its constraints the first time a card
  /// actually provides `floatingCardToolBarItems`, and they're torn down again
  /// when a card without items becomes top (see `updateCardFloatingViewContent`).
  /// So cards that don't use the affordance carry none of its layout and behave
  /// exactly as before it existed.
  ///
  /// The bottom is pinned to the screen's safe area, **not** the card's bottom.
  /// The card always reaches at or below the screen edge, so this is the same
  /// place visually, but it avoids coupling this root-level view to the card
  /// wrapper while the wrapper animates during push/pop — that coupling
  /// corrupted the card's position layout for *every* card. Horizontal alignment
  /// stays relative to the card (its x/width don't move during a vertical card
  /// transition); the leading/trailing inequality clamps keep a wide row from
  /// overflowing the card for any alignment.
  private func installCardFloatingViewIfNeeded() {
    guard cardFloatingView.superview == nil else { return }
    let container = cardOverlayView
    container.addSubview(cardFloatingView)

    cardFloatingCenterXConstraint = cardFloatingView.centerXAnchor.constraint(equalTo: cardWrapperContent.centerXAnchor)
    cardFloatingLeadingConstraint = cardFloatingView.leadingAnchor.constraint(equalTo: cardWrapperContent.leadingAnchor, constant: 16)
    cardFloatingTrailingConstraint = cardFloatingView.trailingAnchor.constraint(equalTo: cardWrapperContent.trailingAnchor, constant: -16)

    NSLayoutConstraint.activate([
      cardFloatingView.leadingAnchor.constraint(greaterThanOrEqualTo: cardWrapperContent.leadingAnchor, constant: 16),
      cardFloatingView.trailingAnchor.constraint(lessThanOrEqualTo: cardWrapperContent.trailingAnchor, constant: -16),
      cardFloatingView.bottomAnchor.constraint(equalTo: container.safeAreaLayoutGuide.bottomAnchor, constant: -16),
    ])

    applyCardFloatingAlignment(.center)
  }

  /// Activates the position constraint(s) for the given alignment. `.fill` pins
  /// both edges so the row stretches across the card; the others pin a single
  /// edge or the centre and let the row size to its content.
  private func applyCardFloatingAlignment(_ alignment: TGCard.FloatingCardToolBarAlignment) {
    cardFloatingCenterXConstraint?.isActive = false
    cardFloatingLeadingConstraint?.isActive = false
    cardFloatingTrailingConstraint?.isActive = false

    switch alignment {
    case .center:
      cardFloatingCenterXConstraint?.isActive = true
    case .leading:
      cardFloatingLeadingConstraint?.isActive = true
    case .trailing:
      cardFloatingTrailingConstraint?.isActive = true
    case .fill:
      cardFloatingLeadingConstraint?.isActive = true
      cardFloatingTrailingConstraint?.isActive = true
    }
  }

  private func setupGestures() {
    
    // Panner for dragging cards up and down
    if panningAllowed {
      let panGesture = UIPanGestureRecognizer()
      panGesture.addTarget(self, action: #selector(handlePan))
      panGesture.delegate = self
      panGesture.isEnabled = mode == .floating
      cardWrapperContent.addGestureRecognizer(panGesture)
      panner = panGesture
    }
    
    // Tapper for tapping the title of the cards
    let cardTapper = UITapGestureRecognizer()
    cardTapper.addTarget(self, action: #selector(handleCardTap))
    cardTapper.delegate = self
    cardTapper.isEnabled = mode == .floating
    cardWrapperContent.addGestureRecognizer(cardTapper)
    self.cardTapper = cardTapper

    // Tapper for tapping the map shadow
    let mapTapper = UITapGestureRecognizer()
    mapTapper.addTarget(self, action: #selector(handleMapTap))
    mapTapper.delegate = self
    mapTapper.isEnabled = mode == .floating
    mapShadow.addGestureRecognizer(mapTapper)
    self.mapShadowTapper = mapTapper
    
#if !os(visionOS)
    // Edge panning to go back
    let edgePanner = UIScreenEdgePanGestureRecognizer()
    edgePanner.addTarget(self, action: #selector(popMaybe))
    edgePanner.isEnabled = mode == .floating
    edgePanner.edges = traitCollection.layoutDirection == .leftToRight ? .left : .right
    view.addGestureRecognizer(edgePanner)
    self.edgePanner = edgePanner
#endif
  }
  
  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if view.superview != nil, !usesSystemSheet {
      // This is the distance from the top edge of the card to the
      // bottom of the header view and determines where the card
      // rests on the screen.
      let distanceFromHeaderView: CGFloat
      
      // We may present another view over it and when that view is
      // dismissed, this gets called again, so we check where the
      // card currently sits to ensure UI is consistent before and
      // after the view presentation.
      switch (mode, cardPosition) {
      case (.sidebar, _):    distanceFromHeaderView = 0
      case (_, .collapsed):  distanceFromHeaderView = collapsedMinY
      case (_, .peaking):    distanceFromHeaderView = peakY
      case (_, .extended):   distanceFromHeaderView = extendedMinY
      }
      mapViewController.additionalSafeAreaInsets = updateCardPosition(y: distanceFromHeaderView)
    }
    
    topCard?.willAppear(animated: animated)
  }
  
  override open func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    if animated == false {
      // FFS! This seems to be the only time we get the correct frame after
      // restoring. So we'll have to fix up positions again here.
      fixPositioning()
    }
    
    if !isVisible {
      // wouldn't yet have told topCard that it'll appear
      topCard?.willAppear(animated: false)
    }

    topCard?.didAppear(animated: animated)
    isVisible = true
    
    updateSystemSheetPresentation()
  }
  
  override open func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    topCard?.willDisappear(animated: animated)
    isVisible = false
    
    // The sheet would otherwise stay on screen when, say, another view
    // controller gets pushed over this one. It comes back in `viewDidAppear`.
    if sheetHost?.presentedViewController == nil {
      uninstallSystemSheet(animated: false)
    }
  }
  
  // MARK: - Presenting
  
  // `@preconcurrency` as callers might not be isolated to the main actor yet,
  // which UIKit tolerates for its own `present` and `dismiss`.
  
  @preconcurrency
  open override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
    guard let sheetHost, viewControllerToPresent !== sheetHost else {
      return super.present(viewControllerToPresent, animated: flag, completion: completion)
    }
    routePresentation(of: viewControllerToPresent, above: sheetHost, animated: flag, completion: completion)
  }
  
  @preconcurrency
  open override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
    guard let sheetHost, presentedViewController === sheetHost else {
      return super.dismiss(animated: flag) { [weak self] in
        completion?()
        self?.updateSystemSheetPresentation()
      }
    }
    routeDismissal(above: sheetHost, animated: flag, completion: completion)
  }
  
  override open func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    topCard?.didDisappear(animated: animated)
  }
  
  open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    
    coordinator.animate(alongsideTransition: { [unowned self] _ in
      self.updateContentWrapperHeightConstraint()
    }, completion: nil)
  }
  
  open override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
    super.willTransition(to: newCollection, with: coordinator)
    
    // Leave the sheet before the size classes change, as the sheet would
    // otherwise go full screen, and get it back once they have changed.
    if usesSystemSheet, !wantsSystemSheet(for: newCollection) {
      uninstallSystemSheet(animated: false)
    } else if !usesSystemSheet, wantsSystemSheet(for: newCollection) {
      coordinator.animate(alongsideTransition: nil) { [weak self] _ in
        self?.updateSystemSheetPresentation()
      }
    }
  }
  
  override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    
    cardWrapperHeightConstraint.constant = extendedMinY * -1
    
    // When trait collection changes, try to keep the same card position
    if let previous = previousCardPosition, !usesSystemSheet {
      // Note: Ideally, we'd determine the direction by whether the available
      // height of VC increased or decreased, but for simplicity just using
      // `up` is fine.
      let location = cardLocation(forDesired: previous, direction: .up)
      mapViewController.additionalSafeAreaInsets = updateCardPosition(y: location.y)
    }

    // The position of a card's header also depends on size classes
    updateHeaderStyle()
    updateHeaderConstraints()
    
    // The visibility of floating views depends on size classes too.
    updateFloatingViewsVisibility()
    
    // When we started a paging card in the peak state while the device is in
    // portrait mode, all of its contents are not scrollable. If we now switch
    // to landscape mode, the card will be in the extended state, which requires
    // the card's contents to be scrollable. Hence, we reenable the scolling.
    updateCardScrolling(allow: true, view: topCardView)
    
    if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass
        || previousTraitCollection?.verticalSizeClass != traitCollection.verticalSizeClass {
      // In case `willTransition` wasn't called, e.g., when embedded
      DispatchQueue.main.async { [weak self] in
        self?.updateSystemSheetPresentation()
      }
    }
    
    topCard?.traitCollectionDidChange(previousTraitCollection)
  }
  
  func updateCardScrolling(allow: Bool, view: TGCardView?) {
    let allowScrolling = allow || UIAccessibility.isVoiceOverRunning || mode == .sidebar || usesSystemSheet
    view?.allowContentScrolling(allowScrolling)
  }
  
  open override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    if view.superview != nil, !mapView.frame.isEmpty {
      if !didAddInitialCards {
        didAddInitialCards = true
        
        // These get pushed the classic way and move into the sheet once we've
        // appeared. Keep them hidden until then.
        isAwaitingSystemSheet = wantsSystemSheet(for: traitCollection)
        
        initialCards.forEach { push($0, animated: false, allowToNotify: $0 == initialCards.last, completionHandler: nil) }
      }
      
      fixPositioning()
      
      if isVisible, !usesSystemSheet, presentedViewController == nil, topCardView != nil, wantsSystemSheet(for: traitCollection) {
        // We wanted a sheet earlier, but couldn't show it, e.g., as something
        // else was presented at the time. Try again.
        DispatchQueue.main.async { [weak self] in
          self?.updateSystemSheetPresentation()
        }
      }
    }
  }
  
  private func fixPositioning() {
    let previousScrollOffset = topCardView?.contentScrollView?.contentOffset.y

    statusBarBlurHeightConstraint.constant = topOverlap
    topCardView?.adjustContentAlpha(to: contentAlpha(for: cardPosition))
    topCardView?.setSeparatorVisibility(forceHidden: forcesSeparatorHidden(for: cardPosition))
    updateFloatingViewsConstraints()
    updateTopInfoViewConstraints()
    view.setNeedsUpdateConstraints()
    
    if !mapView.frame.isEmpty {
      let edgePadding = mapEdgePadding(for: cardPosition)
      if let mapManager = topCard?.mapManager, mapManager.edgePadding != edgePadding {
        mapManager.edgePadding = edgePadding
      }
    }
    
    if let scrollView = topCardView?.contentScrollView {
      view.updateConstraintsIfNeeded() // to get the correct frames

      let adjustedBottom: CGFloat
      if usesSystemSheet {
        // The cards are as high as the extended sheet, and the scroll view
        // adjusts for the sheet's safe area by itself
        adjustedBottom = 0
      } else if cardIsNextToMap(in: traitCollection) {
        adjustedBottom = view.safeAreaInsets.bottom
      } else {
        adjustedBottom = headerView.frame.maxY + view.safeAreaInsets.top - view.safeAreaInsets.bottom
      }
      
      scrollView.contentInset.bottom = adjustedBottom
      scrollView.verticalScrollIndicatorInsets.bottom = adjustedBottom
      
      if topCard?.autoIgnoreContentInset == true, let previousScrollOffset {
        // Changing the bottom scrolls, so we go back to where it was
        scrollView.contentOffset.y =  previousScrollOffset
      }
    }
  }
  
  
  // MARK: - Card positioning
  
  /// The current card position, inferred from the current drag position of the card
  public var cardPosition: TGCardPosition {
    guard mode == .floating else { return .extended }
    if let sheetPosition { return sheetPosition }
    
    let cardY = cardWrapperDesiredTopConstraint.constant
    
    // Add it a bit of extra space around the switch-over to still detect
    // same position after hiding/showing bars
    let peakMargin = max(extendedMinY, peakY - 44)
    let collapsedMargin = max(peakY, collapsedMinY - 44)
    
    switch (cardY, traitCollection.verticalSizeClass) {
    case (0...peakMargin, _):                       return .extended
    case (peakMargin...collapsedMargin, .regular):  return .peaking
    default:                                        return .collapsed
    }
  }
  
  var extendedMinY: CGFloat {
    var value = topOverlap
    
    if mode == .floating {
      let bottomMinSpace = view.safeAreaInsets.bottom > 0 ? Constants.minMapSpaceWithHomeIndicator : Constants.minMapSpace
      value += bottomMinSpace
    }
    
    return value
  }
  
  fileprivate var collapsedMinY: CGFloat {
    // It is save to use the full height of the frame, when actually
    // positioning the card, the fixedCardWrapperTopConstraint will
    // make sure that the top of the card remains visible.
    return view.frame.height
  }
  
  fileprivate var peakY: CGFloat {
    return (collapsedMinY - extendedMinY) / 2
  }
  
  /// The current amount of points of content at the top of the view
  /// that's overlapping with the map. Includes status bar, if visible.
  fileprivate var topOverlap: CGFloat {
    guard isViewLoaded else { return 0 }
    return view.safeAreaInsets.top
  }

  /// The edge padding for the map that map managers should use
  /// to determine the zoom and scroll position of the map.
  ///
  /// - Note: This is the card's overlap for the collapsed and peaking
  ///         card positions, and capped at the peaking card position
  ///         for the extended overlap (to avoid only having a tiny
  ///         map area to work with).
  func mapEdgePadding(for position: TGCardPosition) -> UIEdgeInsets {
    assert(mapView.frame.isEmpty == false, "Don't call this before we have a map view frame.")
    let top: CGFloat
    let bottom: CGFloat
    let left: CGFloat
    
    if usesSystemSheet, let sheetBottom = sheetHeight(for: position == .collapsed ? .collapsed : .peaking) {
      // As below, the card's overlap but capped at the peaking position
      left = 0
      top = isShowingHeader ? 0 : topOverlap
      bottom = sheetBottom
      
    } else if cardIsNextToMap(in: traitCollection) {
      // The map is to the right of the card, which we account for when not collapsed
      let ignoreCard = (position == .collapsed && traitCollection.verticalSizeClass == .regular) || cardWrapperShadow.isHidden
      left = ignoreCard ? 0 : cardWrapperShadow.frame.maxX
      bottom = 0
      top = topOverlap
    } else {
      // Map is always between the top and the card
      left = 0
      let cardY: CGFloat
      switch position {
      case .extended, .peaking: cardY = peakY
      case .collapsed:          cardY = collapsedMinY - 75 // not entirely true, but close enough
      }
      
      top = isShowingHeader ? 0 : topOverlap
      
      // We call this method at times where the map view hasn't been resized yet. We
      // guess the height by just taking the larger side since the card is not next
      // to the map, meaning we're in portrait.
      let height = max(mapView.frame.width, mapView.frame.height)
      bottom = height - cardY
    }
    
    return UIEdgeInsets(top: top, left: left, bottom: bottom, right: 0)
  }
  
  /// Call this whenever the card position changes to properly configure the map shadow
  ///
  /// - Parameter position: New card position
  func updateMapShadow(for position: TGCardPosition) {
    // The map stays interactive next to a system sheet
    let showShadow = position == .extended && !usesSystemSheet
    mapShadow.alpha = showShadow ? Constants.mapShadowVisibleAlpha : 0
    mapShadow.isUserInteractionEnabled = showShadow
  }
  
  func toggleCardWrappers(hide: Bool, prepareOnly: Bool = false) {
    if mode == .sidebar {
      sidebarBackground.alpha = hide ? 0 : 1
    } else {
      sidebarBackground.alpha = 0
    }
    // With a system sheet, the card wrapper is just an invisible placeholder
    cardWrapperShadow.alpha = hide || usesSystemSheet || isAwaitingSystemSheet ? 0 : 1

    if !prepareOnly {
      if mode == .sidebar {
        sidebarBackground.isHidden = hide
      } else {
        sidebarBackground.isHidden = true
      }
      cardWrapperShadow.isHidden = hide
    }
  }
  
  
  /// Call this if you changed the status of the toolbar at the bottom, it might not be reflected automatically,
  /// so it's best to call this to make sure it is.
  public func didUpdateToolbarVisibility(animated: Bool = true) {
    let mapInsets = self.updateCardPosition(y: cardWrapperDesiredTopConstraint.constant)
    
    view.setNeedsUpdateConstraints()
    UIView.animate(withDuration: animated ? 0.25 : 0) {
      self.view.updateConstraints()
      self.mapViewController.additionalSafeAreaInsets = mapInsets
    }
  }
  
  /// This method updates the constraint controlling the height of the card's content
  /// wrapper.
  private func updateContentWrapperHeightConstraint() {
    // It is important to keep in mind that this constraint is relative to the height
    // of the map view.
    
    // This is the base value and is used when the card takes up the entire width of
    // the screen, i.e., when the isn't placed on the side. In this case, we are not
    // required to account for the space taken up by the header view as the map sits
    // directly below the header.
    var adjustment = extendedMinY
    
    if cardIsNextToMap(in: traitCollection) {
      // When the card is placed on the side, the map view takes up the entire screen,
      // as such, we need to add any space taken up by the header view.
      if isShowingHeader {
        adjustment += 20 + self.headerView.frame.height
      }
    }
    
    // This reads the height of the card's content wrapper is equal to the height of
    // the map view minus the adjustment.
    cardWrapperHeightConstraint.constant = -1 * adjustment
  }
  
  private func cardIsNextToMap(in traitCollections: UITraitCollection) -> Bool {
    switch (mode, traitCollections.verticalSizeClass, traitCollections.horizontalSizeClass) {
    case (.sidebar, _, _),
         (_, .compact, _),
         (_, _, .regular): return true
    default: return false
    }
  }
  
}

// MARK: - Access Cards & Card Views

extension TGCardViewController {
  
  public var topCard: TGCard? {
    return cards.last?.card
  }
  
  var topCardView: TGCardView? {
    return cards.last?.view
  }
  
}

// MARK: - Card stack management

extension TGCardViewController {
  
  func cardLocation(forDesired desired: TGCardPosition?, direction: Direction)
      -> (position: TGCardPosition, y: CGFloat) {
        
    guard mode == .floating else {
      return (.extended, extendedMinY)
    }
        
    let position = desired ?? cardPosition
    
    switch (position, traitCollection.verticalSizeClass, direction) {
    case (_, .compact, _):          return (.extended, extendedMinY)
    case (.extended, _, _):         return (.extended, extendedMinY)
    case (.peaking, .regular, _):   return (.peaking, peakY)
    case (.peaking, _, .up):        return (.extended, extendedMinY)
    case (.peaking, _, .down):      return (.collapsed, collapsedMinY)
    case (.collapsed, _, _):        return (.collapsed, collapsedMinY)
    }
  }
  
  // Yes, these are long. We rather keep them together like this (for now).
  // swiftlint:disable function_body_length
  // swiftlint:disable cyclomatic_complexity

  /// Pushes a new card
  ///
  /// - Parameters:
  ///   - top: The new card to show
  ///   - animated: Whether it should appear animated. Default: `true`
  ///   - copyStyle: Whether the style/theme of the previous card should be
  ///       re-applied to the new card. Default: `true`
  ///   - completionHandler: Completion handler called once appeared, after any
  ///       animations
  public func push(_ top: TGCard,
                   animated: Bool = true,
                   copyStyle: Bool = true,
                   completionHandler: (() -> Void)? = nil
  ) {
    push(top, animated: animated, copyStyle: copyStyle, allowToNotify: true, completionHandler: completionHandler)
  }
    
  private func push(_ top: TGCard,
                    animated: Bool,
                    copyStyle: Bool = true,
                    allowToNotify: Bool,
                    completionHandler: (() -> Void)?
  ) {
    guard isViewLoaded else {
      return assertionFailure("Tried to push before view was loaded")
    }
    
    // Set the controller on the top card earlier, because we may want
    // to ask the card to do something on willAppear, e.g., show sticky 
    // bar, which requires access to this property.
    top.controller = self
    
    isTransitioningCards = true
    defer { isTransitioningCards = false }
    
    // 1. Determine where the new card will go
    let forceExtended = (top.mapManager == nil) || (cardPosition == .extended && UIAccessibility.isVoiceOverRunning)
    let animateTo = cardLocation(forDesired: forceExtended ? .extended : top.initialPosition, direction: .down)

    // 2. Updating card logic and informing of transition
    let oldTop = cardWithView(atIndex: cards.count - 1)
    let oldShadowFrame = cardWrapperShadow.frame
    let notify = isVisible && allowToNotify
    if notify {
      oldTop?.card.willDisappear(animated: animated)
    }
    
    if let oldTop {
      cards.removeLast()
      cards.append( (oldTop.card, cardPosition, oldTop.view) )
    }
    
    // 3. Create and configure the new view
    
    // Copying style from old card to new card MUST be called before
    // new card builds its card view.
    if copyStyle, let oldCard = oldTop?.card {
      oldCard.copyStyling(to: top)
    }
    
    let cardView = top.buildCardView()
    cards.append( (top, animateTo.position, cardView) )
        
    if let cardView {
      cardView.dismissButton?.addTarget(self, action: #selector(closeTapped(sender:)), for: .touchUpInside)
      let showClose = (delegate != nil || cards.count > 1) && top.showCloseButton
      cardView.updateDismissButton(show: showClose, isSpringLoaded: navigationButtonsAreSpringLoaded)
      
      // On device with home indicator, we want only the header part of a card view is
      // visible when the card is in collapsed state. If we don't adjust the alpha as
      // below, since the card view is placed on the top of the bottom safe layout guide,
      // which is an additional 34px on iPhone X, we will see part of the card content
      // coming through.
      cardView.adjustContentAlpha(to: contentAlpha(for: animateTo.position))
      cardView.setSeparatorVisibility(forceHidden: forcesSeparatorHidden(for: animateTo.position))
      
      // This allows us to continuously pull down the card view while its
      // content is scrolled to the top. Note this only applies when the
      // card isn't being forced into the extended position.
      if !forceExtended, panningAllowed {
        cardView.contentScrollView?.panGestureRecognizer.addTarget(self, action: #selector(handleInnerPan(_:)))
      }
    
      // 4. Place the new view coming, preparing to animate in from the bottom
      cardView.frame = cardWrapperContent.bounds
      if animated, usesSystemSheet {
        // Cross-fade in place, as the sheet is already there. Sliding up a card
        // within the sheet would look odd.
        cardView.alpha = 0
      } else if animated {
        let offset = cardView.convert(.init(x: 0, y: mapViewWrapper.frame.maxY), to: cardWrapperShadow).y
        cardView.frame.origin.y = offset
        
        cardWrapperEffectView.frame.origin.y = offset
      }
      applyPresentationStyle(to: cardView)
      cardWrapperContent.addSubview(cardView)
      
      // Give AutoLayout a nudge to layout the card view, now that we have
      // the right height. This is so that we can use `cardView.headerHeight`.
      let previousInset = cardView.contentScrollView?.contentOffset.y
      cardView.setNeedsUpdateConstraints()
      cardView.layoutIfNeeded()
      if topCard?.autoIgnoreContentInset == true, let previousInset {
        cardView.contentScrollView?.contentOffset.y = previousInset
      }
    }
    
    // 5. Special handling of when the new top card has no map content
    updatePannerInteractivity()
    updateGrabHandleVisibility()
    
    let header = top.buildHeaderView()
    if let header = header {
      // Keep this to restore it later when hiding the header
      if previousStatusBarStyle == nil {
        previousStatusBarStyle = preferredStatusBarStyle
      }
      
      header.closeButton?.addTarget(self, action: #selector(closeTapped(sender:)), for: .touchUpInside)
      header.closeButton?.isSpringLoaded = navigationButtonsAreSpringLoaded
      header.rightButton?.isSpringLoaded = navigationButtonsAreSpringLoaded
      showHeader(content: header, animated: animated)
    } else if isShowingHeader {
      hideHeader(animated: animated)
    }
    
    // Incoming card has its own top and bottom floating views.
    updateFloatingViewsContent(card: top)
    
    // 6. Set new position of the wrapper (which is relative to the header)
    updateCardStructure(card: cardView, position: .collapsed)
    if usesSystemSheet {
      // Like with the classic panner, pushing re-enables dragging
      isSheetDraggingEnabled = true
      sheetTargetPosition = animateTo.position
    } else {
      mapViewController.additionalSafeAreaInsets = updateCardPosition(y: animateTo.y)
    }
    
    // Notify that we have completed building the card view and its header view.
    top.cardView = cardView
    top.didBuild(cardView: cardView, headerView: header)

    // Cards commonly configure their toolbar items in `didBuild`, which runs
    // *after* the floating-view refresh above. Pick up any card-attached
    // floating items now that the card has been built, so they aren't missed.
    updateCardFloatingViewContent(card: top)
    
    // Before the new card fades in, so that its own close button doesn't
    updateSheetBarItems()
    
    // The previous call can cause a glitch where the render loop is run, if
    // the cards to certain things. To avoid this, we revert back to the old
    // frame, just in case.
    #if DEBUG
    if let newInitial = top.initialPosition, cardPosition != newInitial, !cardWrapperShadow.frame.origin.equalTo(oldShadowFrame.origin) {
      print("""
          === TGCardViewController misuse ==================================
          WARNING: Your implementation of TGCard.didBuild caused a layout
          cycle, which leads to a UI glitch when pushing cards. Review your
          code.
          ==================================================================
          """)
    }
    #endif
    
    if notify {
      top.willAppear(animated: animated)
    }
    
    // 7. Hand over the map, we do this after building the card as cards
    // own the map manager, and they might want to prepare it.
    if oldTop?.card.mapManager !== top.mapManager {
      oldTop?.card.mapManager?.cleanUp(mapView, animated: animated)
      top.mapManager?.takeCharge(of: mapView, edgePadding: mapEdgePadding(for: animateTo.position), animated: animated)
    }
    top.delegate = self

    // Since the header view may be animated in & out, it's best to update the
    // height of the card's content wrapper.
    updateContentWrapperHeightConstraint()
    
    view.setNeedsUpdateConstraints()
    
    // 8. Do the transition, optionally animated
    // We insert a temporary shadow underneath the new top view and above the
    // old. Only do that if the previous transition completed, i.e., we didn't
    // already have such a shadow.
    
    if let oldTop, animated, let cardView, cardTransitionShadow == nil, !usesSystemSheet {
      if #available(iOS 26.0, visionOS 26.0, *), let oldView = oldTop.view, let container = cardTransitionContainer, let snapshot = oldView.snapshotView(afterScreenUpdates: false) {
        var oldFrame = oldView.bounds
        oldFrame.origin = oldView.convert(oldView.bounds.origin, to: container)
        oldView.alpha = 0
        
#if os(visionOS)
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
#else
        let visualEffectView = UIVisualEffectView(effect: UIGlassEffect(style: .regular))
#endif
        visualEffectView.contentView.addSubview(snapshot)
        visualEffectView.frame = oldFrame
        container.insertSubview(visualEffectView, belowSubview: cardTransitionAnchor)
        cardTransitionShadow = visualEffectView
      } else {
        let shadow = TGCornerView(frame: cardWrapperContent.bounds)
        shadow.frame.size.height += 50 // for bounciness
        shadow.backgroundColor = .black
        shadow.alpha = 0
        cardWrapperContent.insertSubview(shadow, belowSubview: cardView)
        cardTransitionShadow = shadow
      }
    }

    let cardAnimations = {
      self.toggleCardWrappers(hide: cardView == nil, prepareOnly: true)

      guard let cardView else { return }
      self.updateMapShadow(for: animateTo.position)
      if self.usesSystemSheet {
        cardView.alpha = 1
        oldTop?.view?.alpha = 0
        return
      }
      cardView.frame = self.cardWrapperContent.bounds
      self.cardWrapperEffectView.frame = cardView.frame
      self.cardTransitionShadow?.alpha = 0.15
    }
    if self.mode != .floating {
      cardAnimations()
      oldTop?.view?.alpha = 0
    }

    // In some cases, the cardWrapperShadow frame might already have been
    // updated before the animation was applied. If that happaned, we reset
    // it temporarily back and animate it.
    // Also animate the shadow (and the old top card) to the new position.
    let newShadow = cardWrapperShadow.frame
    let fixUpShadow = !newShadow.origin.equalTo(oldShadowFrame.origin)
    if fixUpShadow {
      self.cardWrapperShadow.frame = oldShadowFrame
    }

    applySheetPosition(animateTo.position, animated: animated)
    
    UIView.animate(
      withDuration: animated ? (usesSystemSheet ? Constants.sheetCrossFadeDuration : Constants.pushAnimationDuration) : 0,
      delay: 0,
      usingSpringWithDamping: usesSystemSheet ? 1 : 0.75,
      initialSpringVelocity: 0,
      options: [.curveEaseInOut],
      animations: {
        self.view.layoutIfNeeded()
        if fixUpShadow {
          self.cardWrapperShadow.frame = newShadow
        }
        self.updateFloatingViewsVisibility()
        if self.mode == .floating {
          cardAnimations()
        }
      },
      completion: { _ in
        self.updateCardScrolling(allow: animateTo.position == .extended, view: cardView)
        self.previousCardPosition = animateTo.position
        if let oldView = oldTop?.view, oldView !== self.topCardView {
          // Only if it's still covered, i.e., it wasn't popped back to already
          self.detachCoveredCardView(oldView)
        }
        if notify {
          oldTop?.card.didDisappear(animated: animated)
          top.didAppear(animated: animated)
          top.didMove(to: animateTo.position, animated: animated)
        }
        self.cardTransitionShadow?.removeFromSuperview()
        self.cardTransitionShadow = nil
        self.updateForNewPosition(position: animateTo.position)
        self.updateResponderChainForNewTopCard()
        self.toggleCardWrappers(hide: cardView == nil)
        self.updateSheetContentScrollView()
        self.updateSystemSheetPresentation()
        if let preferred = top.preferredView {
          UIAccessibility.post(notification: .screenChanged, argument: preferred)
        }
        completionHandler?()
      }
    )
  }
  // swiftlint:enable function_body_length
  // swiftlint:enable cyclomatic_complexity

  fileprivate func cardWithView(atIndex index: Int)
    -> (card: TGCard, lastPosition: TGCardPosition, view: TGCardView?)? {
    let cards = self.cards
    guard index >= 0, index < cards.count else { return nil }
    return cards[index]
  }
  
  @objc @discardableResult
  func popMaybe() -> Bool {
    guard let top = topCard, top != rootCard else { return false }
    pop()
    return true
  }
  
  // Yes, these are long. We rather keep them together like this (for now).
  // swiftlint:disable function_body_length
  // swiftlint:disable cyclomatic_complexity
  @objc
  public func pop(animated: Bool = true, completionHandler: (() -> Void)? = nil) {
    if let delegate = delegate, cards.count == 1 {
      // popping last one, let delegate dismiss
      delegate.requestsDismissal(for: self)
      return
    }
    
    guard let currentTopCard = topCard, !isPopping else {
      return
    }

    isPopping = true
    isTransitioningCards = true
    defer { isTransitioningCards = false }
    let newTop = cardWithView(atIndex: cards.count - 2)
    let topView = topCardView
    
    // 1. Updating card logic and informing of transitions
    let notify = isVisible
    if notify {
      newTop?.card.willAppear(animated: animated)
      currentTopCard.willDisappear(animated: animated)
    }
    if panningAllowed {
      topView?.contentScrollView?.panGestureRecognizer.removeTarget(self, action: nil)
    }

    // We update the stack immediately to allow calling this many times
    // while we're still animating without issues
    cards.remove(at: cards.count - 1)
    
    // 2. Hand over the map
    if currentTopCard.mapManager !== newTop?.card.mapManager {
      currentTopCard.mapManager?.cleanUp(mapView, animated: animated)
      newTop?.card.mapManager?.takeCharge(of: mapView,
                                          edgePadding: mapEdgePadding(for: newTop?.lastPosition ?? .collapsed),
                                          animated: animated)
    }
    
    // 3. Special handling of when the new top card has no map content
    updatePannerInteractivity(for: newTop)
    updateGrabHandleVisibility(for: newTop)
    
    // TODO: It'd be better if we didn't have to build the header again, but could
    //       just re-use it from the previous push. 
    // See https://gitlab.com/SkedGo/tripgo-cards-ios/issues/7.
    if let header = newTop?.card.buildHeaderView() {
      showHeader(content: header, animated: animated)
    } else if isShowingHeader {
      hideHeader(animated: animated)
    }
    
    // 4. Determine and set new position of the card wrapper (relative to header!)
    if let newView = newTop?.view {
      reattachCardView(newView, below: topView)
      if animated, usesSystemSheet {
        newView.alpha = 0 // and cross-fade below
      }
    }
    updateSheetBarItems()

    // We only animate to the previous position if the card obscures the map
    updateCardStructure(card: newTop?.view, position: newTop?.lastPosition)
    let animateTo: TGCardPosition
    let forceExtended = newTop?.card.mapManager == nil || (cardPosition == .extended && UIAccessibility.isVoiceOverRunning)
    if forceExtended || !cardIsNextToMap(in: traitCollection) {
      let target = cardLocation(forDesired: forceExtended ? .extended : newTop?.lastPosition, direction: .down)
      animateTo = target.position
      if usesSystemSheet {
        // Like with the classic panner, popping re-enables dragging
        isSheetDraggingEnabled = true
        sheetTargetPosition = target.position
      } else {
        mapViewController.additionalSafeAreaInsets = updateCardPosition(y: target.y)
      }
    } else {
      animateTo = cardPosition
    }
    
    // Since the header may be animated in and out, it's safer to update the height
    // of the card's content wrapper.
    updateContentWrapperHeightConstraint()
    
    // Before animating views in and out, restore both top and bottom floating views
    // to previous card's values. Note that, we force a clean up of floating views
    // because the popping card may have added views that are only applicable to it-
    // self.
    updateFloatingViewsContent(card: newTop?.card)
    
    // Notify that constraints need to be updated in the next cycle.
    view.setNeedsUpdateConstraints()

    // 5. Do the transition, optionally animated.
    // We animate the view moving back down to the bottom
    // we also temporarily insert a shadow view again, if there's a card below    
    if animated, cardTransitionShadow == nil, let topView, !usesSystemSheet {
      if #available(iOS 26.0, visionOS 26.0, *), let container = cardTransitionContainer, let snapshot = topView.snapshotView(afterScreenUpdates: false) {
        topView.alpha = 0
        var newFrame = topView.bounds
        newFrame.origin = topView.convert(topView.bounds.origin, to: container)
        
#if os(visionOS)
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
#else
        let visualEffectView = UIVisualEffectView(effect: UIGlassEffect(style: .regular))
#endif
        visualEffectView.contentView.addSubview(snapshot)
        visualEffectView.frame = newFrame
        container.insertSubview(visualEffectView, aboveSubview: cardTransitionAnchor)
        cardTransitionShadow = visualEffectView

      } else {
        let shadow = TGCornerView(frame: cardWrapperContent.bounds)
        shadow.backgroundColor = .black
        shadow.alpha = 0.15
        cardWrapperContent.insertSubview(shadow, belowSubview: topView)
        cardTransitionShadow = shadow
      }
    }
    
    let cardAnimations = {
      self.toggleCardWrappers(hide: newTop?.view == nil, prepareOnly: true)

      self.updateMapShadow(for: animateTo)
      if self.usesSystemSheet {
        topView?.alpha = 0
        newTop?.view?.alpha = 1
      } else if #unavailable(iOS 26.0) {
        self.cardTransitionShadow?.alpha = 0
        topView?.frame.origin.y = self.cardWrapperContent.frame.maxY
      } else {
        self.cardTransitionShadow?.frame.origin.y = self.cardWrapperContent.frame.maxY + 100
      }
      newTop?.view?.adjustContentAlpha(to: self.contentAlpha(for: animateTo))
      newTop?.view?.setSeparatorVisibility(forceHidden: self.forcesSeparatorHidden(for: animateTo))
    }
    
    if mode != .floating {
      cardAnimations()
      topView?.alpha = 0
    }
    
    applySheetPosition(animateTo, animated: animated)
    
    UIView.animate(
      withDuration: animated ? (usesSystemSheet ? Constants.sheetCrossFadeDuration : Constants.pushAnimationDuration * 1.25) : 0,
      delay: 0,
      usingSpringWithDamping: 1,
      initialSpringVelocity: 0,
      options: [.curveEaseInOut],
      animations: {
        self.view.layoutIfNeeded()
        self.updateFloatingViewsVisibility()
        if self.mode == .floating {
          cardAnimations()
        }
      },
      completion: { _ in
        self.updateCardScrolling(allow: animateTo == .extended, view: newTop?.view)
        currentTopCard.controller = nil
        if notify {
          currentTopCard.didDisappear(animated: animated)
          newTop?.card.didAppear(animated: animated)
          newTop?.card.didMove(to: animateTo, animated: animated)
        }
        // This line did crash in Adrian's simulator but only happens rarely; when?!?
        topView?.removeFromSuperview()
        topView?.alpha = 1
        self.cardTransitionShadow?.removeFromSuperview()
        self.cardTransitionShadow = nil
        self.updateForNewPosition(position: animateTo)
        self.updateResponderChainForNewTopCard()
        self.isPopping = false
        self.toggleCardWrappers(hide: newTop?.view == nil)
        self.updateSheetContentScrollView()
        self.updateSystemSheetPresentation()
        if let preferred = newTop?.card.preferredView {
          UIAccessibility.post(notification: .screenChanged, argument: preferred)
        }
        completionHandler?()
      }
    )
  }
  // swiftlint:enable function_body_length
  // swiftlint:enable cyclomatic_complexity

  /// Swaps the current top card with the provided new card
  ///
  /// - Warning: This doesn't work on the root card, will throw an assert in
  ///     in development and do nothing.
  ///
  /// - Parameters:
  ///   - newCard: The new card to present
  ///   - animated: Whether the swap can be animated. Will only be animated if
  ///       the new's card position is different from the current card position.
  public func swap(for newCard: TGCard, animated: Bool = true, onCompletion handler: (() -> Void)? = nil) {
    guard cards.count > 0 else {
      assertionFailure("Trying to swap, but there's no top card. Did you mean to `push`?")
      return
    }
    
    if cards.count == 1 {
      rootCard = newCard
    }
    
    let animatePush = animated
      && newCard.initialPosition != cardPosition

    // Keep this so that we restore it as pushing would otherwise overwrite it
    let previous = self.previousCardPosition
    
    // Push as normal, will also tell card below that it'll disappear
    push(newCard, animated: animatePush) {
      self.previousCardPosition = previous
      
      // Kill the card below
      let poppeeIndex = self.cards.count - 2
      if poppeeIndex >= 0 {
        self.cards[poppeeIndex].view?.removeFromSuperview()
        self.cards.remove(at: poppeeIndex)
      } else {
        assertionFailure()
      }
      
      handler?()
    }    
  }
  
  @objc
  func closeTapped(sender: Any) {
    pop()
  }
}


// MARK: - Dragging the card up and down

extension TGCardViewController {

  enum Direction {
    case up
    case down
    
    init(ofVelocity velocity: CGPoint) {
      if velocity.y < 0 {
        self = .up
      } else {
        self = .down
      }
    }
  }
  
  /// - Returns: The map inset to apply to the map view controller. Set it directly or in an animation block.
  func updateCardPosition(y: CGFloat) -> UIEdgeInsets {
    // The constraint moves the card into place
    cardWrapperDesiredTopConstraint.constant = y
    
    // Adjusting the safe area moves the map's attribution and adjust how it
    // centres the current location, etc.
    var mapInsets = UIEdgeInsets.zero
    if cardIsNextToMap(in: traitCollection) {
      let cardWidth = cardWrapperShadow.isHidden ? 0 : (traitCollection.horizontalSizeClass == .regular ? 360 : view.frame.width * 0.38) // same as in storyboard
      if traitCollection.layoutDirection == .rightToLeft {
        mapInsets.right = cardWidth
      } else {
        mapInsets.left = cardWidth
      }
    } else {
      // Our view has the full height, including what's below safe area insets.
      // The maximum interactive area is that without the bottom and anything
      // covered by the optional header at the top.
      let maxHeight = view.bounds.height - view.safeAreaInsets.bottom - headerView.frame.maxY
      mapInsets.bottom = min(
        maxHeight - peakY, // Don't collapse more than peaking. Instead we
                           // disable the map when extended in a related code
                           // path.
        max(
          maxHeight - y,   // The usual case while dragging.
          cardWrapperMinOverlapTopConstraint.constant // Don't extend beyond
                           // what the card covers when it's collapsed.
        )
      )
      mapInsets.top = headerView.frame.maxY
    }
    if !bottomFloatingView.arrangedSubviews.isEmpty {
      let floatingWidth = bottomFloatingViewWrapper.bounds.width
      if traitCollection.layoutDirection == .rightToLeft {
        mapInsets.left = floatingWidth
      } else {
        mapInsets.right = floatingWidth
      }
    }
    return mapInsets
  }
  
  private func updateCardStructure(card: TGCardView?, position: TGCardPosition?) {
    // Adjusting the safe area moves the map's attribution and adjust how it
    // centres the current location, etc.
    if let cardView = card {
      let bottomOverlap = max(
        Constants.minCardHeightWhenCollapsed,
        cardView.headerHeight(for: position ?? .collapsed)
      )
      cardWrapperMinOverlapTopConstraint.constant = bottomOverlap
    } else {
      cardWrapperMinOverlapTopConstraint.constant = 0
    }
  }
  
  /// Call this whenever the height of the current card's title has changed.
  ///
  /// Generally not necessary to call, unless where you use a custom card title and it's height changed
  /// after the card was first presented.
  public func cardTitleHeightDidChanged() {
    topCardView?.updateConstraintsIfNeeded()
    topCardView?.layoutIfNeeded()

    updateCardStructure(card: topCardView, position: cardPosition)
    
    // The collapsed sheet shows exactly the title
    applySheetPosition(animated: true)
  }
  
  func updateForNewPosition(position: TGCardPosition) {
    previousCardPosition = position
    
    topCardView?.grabHandles.forEach {
      if usesSystemSheet {
        // The sheet's grabber takes over
        $0.isAccessibilityElement = false
      } else {
        updateCardHandleAccessibility(handle: $0, position: position)
      }
    }
    
    let mapIsInteractive = usesSystemSheet || cardIsNextToMap(in: traitCollection) || position != .extended
    mapViewController.isUserInteractionEnabled = mapIsInteractive
    topFloatingViewWrapper.isUserInteractionEnabled = mapIsInteractive
    bottomFloatingViewWrapper.isUserInteractionEnabled = mapIsInteractive
  }
  
  /// Determines where to snap the card wrapper to, considering its current
  /// location and the provided velocity.
  ///
  /// - note:  We only go to peaking state, in regular size class.
  ///
  /// - Parameter velocity: Velocity of movement of card wrapper
  /// - Returns: Desired snap position and y
  fileprivate func determineSnap(for velocity: CGPoint) -> (position: TGCardPosition, y: CGFloat) {
    
    let currentCardY = cardWrapperDesiredTopConstraint.constant
    
    /// Distance travelled after decelerating to zero velocity at constant rate
    func project(initialVelocity: CGFloat, deceleration: UIScrollView.DecelerationRate) -> CGFloat {
      let decelerationRate = deceleration.rawValue
      return (initialVelocity / 1000.0) * decelerationRate / (1.0 - decelerationRate)
    }
    
    let nextCardY = currentCardY + project(initialVelocity: velocity.y, deceleration: .normal)
    
    // First we see if the card is close to a target snap position, then we use that
    let delta: CGFloat = 22
    switch (nextCardY, traitCollection.verticalSizeClass) {
    case (extendedMinY - delta ..< extendedMinY + delta, _):
      return (.extended, extendedMinY)
    case (peakY - delta * 2 ..< peakY + delta * 2, .regular):
      return (.peaking, peakY)
    case (collapsedMinY - delta ..< collapsedMinY + delta, _):
      return (.collapsed, collapsedMinY)
    
    default:
      break // not near a target position
    }
    
    // Otherwise we look into the direction and snap to the next one that way
    // - fallthrough makes sense, so fine to disable
    // swiftlint:disable fallthrough
    // swiftlint:disable no_fallthrough_only
    let direction = Direction(ofVelocity: velocity)
    switch (direction, traitCollection.verticalSizeClass) {
    case (.up, .compact): fallthrough
    case (.up, _) where nextCardY < peakY:
      return (.extended, extendedMinY)
      
    case (.down, .compact): fallthrough
    case (.down, _) where nextCardY > peakY:
      return (.collapsed, collapsedMinY)
      
    default:
      return (.peaking, peakY)
    }
    // swiftlint:enable no_fallthrough_only
    // swiftlint:enable fallthrough
    
  }
  
  fileprivate func animateCardSnap(forVelocity velocity: CGPoint, completion: (() -> Void)? = nil) {
    let snapTo = determineSnap(for: velocity)
    let currentCardY = cardWrapperDesiredTopConstraint.constant
    
    // Now we can animate to the new position
    let direction = Direction(ofVelocity: velocity)
    var duration = direction == .up
      ? Double((currentCardY - snapTo.y) / -velocity.y)
      : Double((snapTo.y - currentCardY) / velocity.y )
    
    // We add a max to not make it super slow when there was
    // barely any velocity.
    // We add a min to it to make sure the alpha transition
    // animates nicely and not too suddenly.
    duration = min(max(duration, Constants.snapAnimationMinimumDuration), 1.3)
    
    let mapInset = updateCardPosition(y: snapTo.y)
    view.setNeedsUpdateConstraints()
    
    UIView.animate(
      withDuration: duration,
      delay: 0.0,
      usingSpringWithDamping: 0.8,
      initialSpringVelocity: 0,
      options: [.allowUserInteraction],
      animations: {
        self.updateMapShadow(for: snapTo.position)
        self.topCardView?.adjustContentAlpha(to: snapTo.position == .collapsed ? 0 : 1)
        self.topCardView?.setSeparatorVisibility(forceHidden: snapTo.position == .collapsed)
        self.updateFloatingViewsVisibility(for: snapTo.position)
        self.view.layoutIfNeeded()
        self.mapViewController.additionalSafeAreaInsets = mapInset
      }, completion: { _ in
        self.topCard?.mapManager?.edgePadding = self.mapEdgePadding(for: snapTo.position)
        self.topCard?.didMove(to: snapTo.position, animated: true)
        self.updateCardScrolling(allow: snapTo.position == .extended, view: self.topCardView)
        self.updateForNewPosition(position: snapTo.position)
        completion?()
      })
  }
  
  @objc
  fileprivate func handlePan(_ recogniser: UIPanGestureRecognizer) {
    guard mode == .floating, !usesSystemSheet else { return }
    
    // Reset dragger state if we aren't currently moving, but ALSO not if it
    // just ended, we don't want to exit early and still snap then. We reset
    // the state at the end of the method for this
    if recogniser.state != .changed, recogniser.state != .ended {
      isDraggingCard = false
    }
    
    let translation = recogniser.translation(in: cardWrapperContent)
    let velocity = recogniser.velocity(in: cardWrapperContent)
    
    let swipeHorizontally = abs(velocity.x) > abs(velocity.y)
    if swipeHorizontally, !isDraggingCard {
      // Cancel our panner, so that we don't keep dragging the card
      // up and down while paging or when swiping to delete.
      recogniser.isEnabled = false
      recogniser.isEnabled = true
      return
    }
    
    isDraggingCard = true
    var currentCardY = cardWrapperDesiredTopConstraint.constant
    
    // Recall that we have a minimum overlap constraint set on the card 
    // view, so that a card does not collapse all the way below the view
    // but has its header remained visible. This min overlap needs to be
    // exceeded if we want to move the card upwards from the collapsed
    // state. This causes a disconnect between gesture and the movement
    // of the card, which is undesirable.
    // 
    // Care needs to be taken when accounting for the card view header.
    // When the device's size class is v(C), card only has two states:
    // collapsed and extended. Until the card has been moved past the
    // extendedY, it remains in collapsed state and we don't want to 
    // adjust the header repeatedly. Instead, we do it only when at the
    // start of recognising gesture.
    if let topCardView = topCardView, cardPosition == .collapsed, recogniser.state == .began {
      let offset = topCardView.headerHeight(for: .collapsed)
      currentCardY -= (offset + view.safeAreaInsets.bottom)
    }
    
    // Reposition the card according to the pan as long as the user
    // is dragging in the range of extended and collapsed
    let newY = currentCardY + translation.y
    if (newY >= extendedMinY) && (newY <= collapsedMinY) {
      recogniser.setTranslation(.zero, in: cardWrapperContent)
      mapViewController.additionalSafeAreaInsets = updateCardPosition(y: newY)
      
      // Set alpha according to scrolling state, for a smooth transition
      // Collapsed: 0, peakY: 1
      let contentAlpha = min(1, max(0, (collapsedMinY - newY) / (collapsedMinY - peakY)))
      topCardView?.adjustContentAlpha(to: contentAlpha)
      
      // Start fading out the floating views when we move away from the peak state position
      // and fading in when we move towards it. The 0.3 is introduced so the fading out
      // happens sooner, i.e., not too far up the peak state position.
      if !cardIsNextToMap(in: traitCollection), newY <= peakY {
        let floatingViewAlpha = min(1, max(0, (peakY - newY) / ((peakY - extendedMinY)*0.3)))
        topFloatingViewWrapper.alpha = 1 - floatingViewAlpha
        bottomFloatingViewWrapper.alpha = 1 - floatingViewAlpha
      }
      
      view.setNeedsUpdateConstraints()
      view.layoutIfNeeded()
    }
    
    // Additionally, when the user is done panning, we'll snap the card
    // to the appropriate state (extended, peaking, collapsed)
    guard recogniser.state == .ended else { return }
    
    isDraggingCard = false
    animateCardSnap(forVelocity: velocity)
  }
  
  @objc
  fileprivate func handleCardTap(_ recogniser: UITapGestureRecognizer) {
    guard mode == .floating else { return }

    switch cardPosition {
    case .peaking, .collapsed: expand()
    case .extended: break
    }
  }
  
  @objc
  fileprivate func handleMapTap(_ recogniser: UITapGestureRecognizer) {
    guard mode == .floating, !usesSystemSheet, cardPosition == .extended, topCard?.mapManager != nil else { return }
    
    switchTo(.peaking, direction: .down, animated: true)
  }
  
  @objc
  fileprivate func handleInnerPan(_ recogniser: UIPanGestureRecognizer) {
    guard
      mode == .floating,
      !usesSystemSheet,
      let scrollView = recogniser.view as? UIScrollView,
      scrollView == topCardView?.contentScrollView,
      panner.isEnabled,
      scrollView.refreshControl == nil
      else { return }
    
    let negativity = scrollView.contentOffset.y + scrollView.contentInset.top
    
    switch (negativity, recogniser.state) {
    case (0 ..< CGFloat.infinity, _):
      // Reset the transformation whenever we get back to positive offset
      scrollView.transform = .identity
      scrollView.scrollIndicatorInsets = scrollView.contentInset // .zero
      
    case (_, .ended), (_, .cancelled):
      // When we finish up, we bring the scroll view back to the state how
      // it's appearing: scrolled to the top with zero inset
      scrollView.transform = .identity
      scrollView.scrollIndicatorInsets = scrollView.contentInset // .zero
      if topCard?.autoIgnoreContentInset == true {
        scrollView.contentOffset = .zero
      }
      
      // Stop the "residual" scroll motion in the scroll view, and instead
      // stay snapped to offset 0.
      //
      // Without this you get funny behaviour if you start a card on expanded
      // but scroll down a little; then you start dragging with scroll to zero
      // you keep scrolling and fling it a little that it snaps to the peaking
      // position.
#if swift(>=5.10) // Proxy for Xcode 15.3+
      if #available(iOS 17.4, visionOS 1.1, *) {
        scrollView.stopScrollingAndZooming()
      }
#endif
      
      guard traitCollection.verticalSizeClass != .compact else {
        return
      }
      
      let velocity = recogniser.velocity(in: cardWrapperContent)
      animateCardSnap(forVelocity: velocity)
      
    case (_, .changed):
      guard traitCollection.verticalSizeClass != .compact else {
        return
      }
      
      // This is where the magic happens: We move the card down and make
      // the scroll view appear to stay in place (it's important to not
      // set the content offset to zero here!)
      self.mapViewController.additionalSafeAreaInsets = updateCardPosition(y: extendedMinY - negativity)
      scrollView.transform = CGAffineTransform(translationX: 0, y: negativity)
      scrollView.verticalScrollIndicatorInsets.top = scrollView.contentInset.top + negativity * -1
      
    default:
      // Ignore other states such as began, failed, etc.
      break
    }
  }

  /// Moves the card to the provided position.
  ///
  /// If position is specified as `peaking` is, but this isn't allowed
  /// due to the trait collections, then it will move to `extended` instead.
  ///
  /// - Parameters:
  ///   - position: Desired position
  ///   - animated: If transition should be animated
  ///   - handler: Closure to execute when the move is completed
  public func moveCard(to position: TGCardPosition, animated: Bool, onCompletion handler: (() -> Void)? = nil) {
    switchTo(position, direction: .up, animated: animated, onCompletion: handler)
  }
  
  fileprivate func switchTo(
    _ position: TGCardPosition,
    direction: Direction,
    animated: Bool,
    onCompletion handler: (() -> Void)? = nil
  ) {
    guard mode == .floating else {
      cardWrapperDesiredTopConstraint.constant = 0
      view.setNeedsUpdateConstraints()
      handler?()
      return
    }
    
    let animateTo = cardLocation(forDesired: position, direction: direction)
    
    if usesSystemSheet {
      UIView.animate(withDuration: animated ? Constants.tapAnimationDuration : 0) {
        self.updateFloatingViewsVisibility(for: animateTo.position)
      }
      applySheetPosition(animateTo.position, animated: animated) {
        self.topCard?.mapManager?.edgePadding = self.mapEdgePadding(for: animateTo.position)
        self.topCard?.didMove(to: animateTo.position, animated: animated)
        self.updateForNewPosition(position: animateTo.position)
        handler?()
      }
      return
    }
    
    let mapInsets = updateCardPosition(y: animateTo.y)
    view.setNeedsUpdateConstraints()
    
    UIView.animate(
      withDuration: animated ? Constants.tapAnimationDuration : 0,
      delay: 0,
      options: [.curveEaseOut],
      animations: {
        self.updateMapShadow(for: animateTo.position)
        self.topCardView?.adjustContentAlpha(to: animateTo.position == .collapsed ? 0 : 1)
        self.topCardView?.setSeparatorVisibility(forceHidden: animateTo.position == .collapsed)
        self.updateFloatingViewsVisibility(for: animateTo.position)
        self.view.layoutIfNeeded()
        self.mapViewController.additionalSafeAreaInsets = mapInsets
    },
      completion: { _ in
        self.topCard?.mapManager?.edgePadding = self.mapEdgePadding(for: animateTo.position)
        self.topCard?.didMove(to: animateTo.position, animated: animated)
        self.updateCardScrolling(allow: animateTo.position == .extended, view: self.topCardView)
        self.updateForNewPosition(position: animateTo.position)
        handler?()
    })
  }
  
  func updatePannerInteractivity(for cardElement:
      (card: TGCard, lastPosition: TGCardPosition, view: TGCardView?)? = nil) {
    guard panningAllowed, mode == .floating, !usesSystemSheet else { return }
    let card = cardElement?.card ?? topCard
    let isForceExtended = card?.mapManager == nil
    panner.isEnabled = !isForceExtended
  }
  
}

// MARK: - Covered cards

extension TGCardViewController {
  
  /// Takes the view of a card that's covered by another card out of the view
  /// hierarchy, so that it doesn't take part in layout, rendering or
  /// accessibility while it can't be seen.
  ///
  /// The view stays alive, as `cards` holds on to it, so it keeps its state, such
  /// as its scroll position, and gets put back by `reattachCardView(_:below:)`
  /// when the card above it gets popped.
  func detachCoveredCardView(_ cardView: TGCardView) {
    cardView.alpha = 0
    cardView.removeFromSuperview()
  }
  
  /// Puts the view of a card that's about to be revealed back into the view
  /// hierarchy, underneath the card that's about to go away.
  func reattachCardView(_ cardView: TGCardView, below topView: UIView?) {
    if cardView.superview !== cardWrapperContent {
      UIView.performWithoutAnimation {
        // The card wrapper might have changed size in the meantime
        cardView.frame = cardWrapperContent.bounds
        if let topView, topView.superview === cardWrapperContent {
          cardWrapperContent.insertSubview(cardView, belowSubview: topView)
        } else {
          cardWrapperContent.addSubview(cardView)
        }
        cardView.layoutIfNeeded()
      }
    }
    cardView.alpha = 1
  }
  
}

// MARK: - Grab handle

extension TGCardViewController {
  
  func updateGrabHandleVisibility(for cardElement:
      (card: TGCard, lastPosition: TGCardPosition, view: TGCardView?)? = nil) {
    let card = cardElement?.card ?? topCard
    let view = cardElement?.view ?? topCardView
    // A system sheet has its own grabber
    let isForceExtended = card?.mapManager == nil || mode == .sidebar || usesSystemSheet
    view?.grabHandles.forEach { $0.alpha = isForceExtended ? 0 : 1 }
  }
}

// MARK: - Info view

extension TGCardViewController {
  
  public var topInfoView: UIView? { topInfoViewWrapper.subviews.first }
  
  public func showInfoView(_ view: UIView, animated: Bool) {
    topInfoViewWrapper.subviews.forEach { $0.removeFromSuperview() }
    topInfoViewWrapper.addSubview(view)
    view.snap(to: topInfoViewWrapper)
    
    topInfoViewWrapper.alpha = 0
    topInfoViewWrapper.isHidden = false
    UIView.animate(withDuration: animated ? 0.25 : 0) {
      self.topInfoViewWrapper.alpha = 1
    }
  }
  
  public func hideInfoView(animated: Bool) {
    UIView.animate(withDuration: animated ? 0.25 : 0, animations: {
      self.topInfoViewWrapper.alpha = 0
    }, completion: { (_) in
      self.topInfoViewWrapper.subviews.forEach { $0.removeFromSuperview() }
      
      // This is to satisfy autolayout
      let dummy = UIView()
      dummy.translatesAutoresizingMaskIntoConstraints = false
      dummy.heightAnchor.constraint(equalToConstant: 0).isActive = true
      dummy.alpha = 0
      self.topInfoViewWrapper.addSubview(dummy)
      dummy.snap(to: self.topInfoViewWrapper)
      
      self.topInfoViewWrapper.isHidden = true
    })
  }
  
  private func updateTopInfoViewConstraints() {
    let min = topFloatingViewWrapper.frame.minX
    let max = cardWrapperShadow.frame.maxX
    let width = view.frame.width
    
    let offset: CGFloat
    if cardIsNextToMap(in: traitCollection) {
      offset = min - (0.5 * (min - max)) - (0.5 * width)
    } else {
      offset = -0.5*(width - min)
    }
    self.topInfoViewWrapperCenterXConstraint.constant = offset
  }
  
}

// MARK: - Floating views

extension TGCardViewController {
  
  public func toggleMapOverlays(show: Bool, animated: Bool = true, completion: ((Bool) -> Void)? = nil) {
    // Map buttons
    self.allowFloatingViews = show
    if show {
      updateFloatingViewsVisibility(for: cardPosition, animated: animated)
    } else {
      fadeMapFloatingViews(true, animated: animated)
    }
    
    UIView.animate(withDuration: animated ? 0.25 : 0) {
      // hide the card and disable all card-based interaction
      if let sheetHost = self.sheetHost {
        sheetHost.presentationController?.containerView?.alpha = show ? 1 : 0
        self.mapBarItems?.alpha = show ? 1 : 0
        self.mapBarItems?.isUserInteractionEnabled = show
      } else {
        self.panner.isEnabled = show
        self.cardWrapperShadow?.isUserInteractionEnabled = show
        self.cardWrapperShadow?.alpha = show ? 1 : 0
      }
      
      // update the map shadow; have to hide it in `extended`
      self.updateMapShadow(for: show ? self.cardPosition : .collapsed)
      
      // adjust the maps insets
      if show {
        self.mapViewController.additionalSafeAreaInsets = self.updateCardPosition(y: self.cardWrapperDesiredTopConstraint.constant)
      } else {
        self.mapViewController.additionalSafeAreaInsets = .zero
      }
    } completion: { finished in
      completion?(finished)
    }
  }
  
  private func deviceIsiPhoneX() -> Bool { view.window?.safeAreaInsets.bottom ?? 0 > 0 }
  
  private func fadeMapFloatingViews(_ fade: Bool, animated: Bool) {
    topFloatingViewWrapper.isHidden = false
    bottomFloatingViewWrapper.isHidden = false
    
    UIView.animate(withDuration: animated ? 0.25: 0) {
      self.topFloatingViewWrapper.accessibilityElements = fade ? [] : nil
      self.topFloatingViewWrapper.alpha = fade ? 0 : 1
      self.topFloatingViewWrapper.isUserInteractionEnabled = !fade
      self.bottomFloatingViewWrapper.accessibilityElements = fade ? [] : nil
      self.bottomFloatingViewWrapper.alpha = fade ? 0 : 1
      self.bottomFloatingViewWrapper.isUserInteractionEnabled = !fade
    } completion: { _ in
      self.topFloatingViewWrapper.isHidden = fade
      self.bottomFloatingViewWrapper.isHidden = false
    }
  }
  
  func updateFloatingViewsVisibility(for position: TGCardPosition? = nil, animated: Bool = false) {
    let fade: Bool
    if !allowFloatingViews {
      fade = true
    } else if cardIsNextToMap(in: traitCollection) {
      // When card is on the side of the map, always show the floating views.
      fade = false
    } else {
      fade = position ?? cardPosition == .extended
    }
    fadeMapFloatingViews(fade, animated: animated)
  }
  
  private func applyToolbarItemStyle() {
    @MainActor
    func apply(on view: UIView) {
      switch buttonStyle.shape {
      case .roundedRect:
        view.layer.cornerRadius = 8
      case .circle:
        view.layer.cornerRadius = view.frame.width / 2
      case .none:
        view.layer.cornerRadius = 0
      }
      
      if let customTint = buttonStyle.tintColor {
        view.tintColor = customTint
      } else {
        view.tintColor = nil
      }

      guard let visualView = view as? UIVisualEffectView else {
        return assertionFailure()
      }
      if #available(iOS 26.0, *) {
#if os(visionOS)
        visualView.effect = UIBlurEffect(style: .regular)
#else
        visualView.effect = UIGlassEffect(style: .regular)
#endif
        visualView.layer.borderWidth = 0
        visualView.layer.shadowOpacity = 0
      } else if buttonStyle.isTranslucent {
        visualView.effect = UIBlurEffect(style: .regular)
        visualView.layer.borderWidth = 0
        visualView.layer.shadowOpacity = 0
      } else {
        visualView.effect = UIBlurEffect(style: .systemThickMaterial)
        visualView.layer.borderColor = UIColor(white: 0, alpha: 0.05).cgColor
        visualView.layer.borderWidth = 0.5
        visualView.layer.shadowOpacity = 0.16
        visualView.layer.shadowColor = UIColor.black.cgColor
        visualView.layer.shadowOffset = .init(width: 0, height: 2)
        visualView.layer.shadowRadius = 4
      }
    }
    
    apply(on: topFloatingViewWrapper)
    apply(on: bottomFloatingViewWrapper)
  }
  
  public func updateMapToolbarItems() {
    updateFloatingViewsContent(card: topCard)
  }
  
  private func updateFloatingViewsContent(card: TGCard?) {
    var topViews: [UIView] = []
    var bottomViews: [UIView] = []
    
    switch locationButtonPosition {
    case .top: topViews = defaultButtons
    case .bottom: bottomViews = defaultButtons
    }
    
    // Because we want to relocate buttons in the top toolbar
    // to the bottom toolbar when header is present, so it is
    // important that we set up bottom toolbar first!
    bottomViews.append(contentsOf: persistentBottomMapToolBarItems)
    if let newBottoms = card?.bottomMapToolBarItems {
      bottomViews.append(contentsOf: newBottoms)
    }
    
    if !bottomViews.isEmpty {
      populateFloatingView(bottomFloatingView, with: bottomViews)
    } else {
      cleanUpFloatingView(bottomFloatingView)
    }
    
    // Now we can proceed with setting up toolbar at the top.
    topViews.append(contentsOf: persistentTopMapToolBarItems)
    if let newTops = card?.topMapToolBarItems {
      topViews.append(contentsOf: newTops)
    }
    
    if !topViews.isEmpty {
      if isShowingHeader {
        // If header is present, we move the buttons that should be in
        // the top toolbar to the bottom.
        bottomViews.append(contentsOf: topViews)
        populateFloatingView(bottomFloatingView, with: bottomViews)
        
        // Don't forget to clean up top toolbar, or items from other
        // cards can still be visible
        cleanUpFloatingView(topFloatingView)
      } else {
        populateFloatingView(topFloatingView, with: topViews)
      }
    } else {
      cleanUpFloatingView(topFloatingView)
    }
    
    // Card-attached floating items (pinned to the card, not over the map).
    updateCardFloatingViewContent(card: card)

    // After contents are updated, we do a round of layout
    // pass, so the wrappers obtain their correct sizes.
    topFloatingViewWrapper.setNeedsLayout()
    topFloatingViewWrapper.layoutIfNeeded()
    bottomFloatingViewWrapper.setNeedsLayout()
    bottomFloatingViewWrapper.layoutIfNeeded()
    
    // Once wrappers have their correct sizes, we can apply
    // the button style. Note, some styles depend on the
    // wrappers' widths, e.g., the circle style.
    applyToolbarItemStyle()
  }

  /// (Re)populates the card-attached floating view from `card`'s
  /// `floatingCardToolBarItems`. Safe to call repeatedly. The view and its
  /// constraints are installed only when a card actually has items, and torn
  /// down again otherwise — so a card without items carries none of the
  /// affordance's layout. Called both during the full floating-view refresh and
  /// right after `didBuild`, since cards commonly configure their items there.
  func updateCardFloatingViewContent(card: TGCard?) {
    if let cardItems = card?.floatingCardToolBarItems, !cardItems.isEmpty {
      installCardFloatingViewIfNeeded()
      populateFloatingView(cardFloatingView, with: cardItems)
      applyCardFloatingAlignment(card?.floatingCardToolBarAlignment ?? .center)
      cardFloatingView.isHidden = false
      cardFloatingView.superview?.bringSubviewToFront(cardFloatingView)
    } else {
      cleanUpFloatingView(cardFloatingView)
      cardFloatingView.isHidden = true
      // Drop the view and its constraints entirely when unused, so a card that
      // doesn't adopt the affordance never has it coupled into the layout.
      cardFloatingView.removeFromSuperview()
    }
  }

  private func updateFloatingViewsConstraints() {
    if cardIsNextToMap(in: traitCollection) {
      bottomFloatingViewBottomConstraint.constant = deviceIsiPhoneX() ? 0 : 8
      bottomFloatingViewTrailingToSafeAreaConstraint.constant = deviceIsiPhoneX() ? 0 : 8
      topFloatingViewTrailingToSafeAreaConstraint.constant = deviceIsiPhoneX() ? 0 : 8
      topFloatingViewTopConstraint.constant = deviceIsiPhoneX() ? view.safeAreaInsets.bottom : 8
    } else {
      bottomFloatingViewBottomConstraint.constant = 8
      bottomFloatingViewTrailingToSafeAreaConstraint.constant = 8
      topFloatingViewTrailingToSafeAreaConstraint.constant = 8
      topFloatingViewTopConstraint.constant = 8
    }
  }
  
  private func populateFloatingView(_ floatingView: UIStackView, with views: [UIView]) {
    // Make sure we start fresh
    cleanUpFloatingView(floatingView)
    
    // Now we add views to the stack
    for (index, view) in views.enumerated() {
      if index != 0 {
        let separator = UIView(frame: .zero)
        if floatingView.axis == .vertical {
          separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        } else {
          separator.widthAnchor.constraint(equalToConstant: 1).isActive = true
        }
        separator.backgroundColor = .separator
        floatingView.addArrangedSubview(separator)
      }
      floatingView.addArrangedSubview(view)
    }
  }
  
  private func cleanUpFloatingView(_ stackView: UIStackView) {
    stackView.arrangedSubviews.forEach {
      stackView.removeArrangedSubview($0)
      $0.removeFromSuperview()
    }
  }
  
}

// MARK: - Card-specific header view

extension TGCardViewController {

  var isShowingHeader: Bool {
    return headerViewTopConstraint.constant > -1
  }
  
  private func updateHeaderStyle() {
    @MainActor
    func applyCornerStyle(to view: UIView) {
      let radius: CGFloat
      if #available(iOS 26.0, *) {
        radius = Constants.iOS26CornerRadius
      } else {
        radius = 12
      }
      let roundAllCorners = cardIsNextToMap(in: traitCollection)
      
      view.layer.maskedCorners = roundAllCorners
        ? [.layerMinXMaxYCorner, .layerMinXMinYCorner,
           .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        : [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
      view.layer.cornerRadius = radius
    }
    
    headerView.backgroundColor = topCard?.style.backgroundColor ?? .white
    applyCornerStyle(to: headerView)
    headerView.subviews
      .compactMap { $0 as? TGHeaderView }
      .forEach { applyCornerStyle(to: $0) }
    
    updateStatusBar(headerIsVisible: isShowingHeader)

    if #available(iOS 26.0, *) {
      // No shadow. Rely on headerEffectView
    } else {
      // same shadow as for card wrapper
      headerView.layer.shadowColor = UIColor.black.cgColor
      headerView.layer.shadowOffset = .zero
      headerView.layer.shadowRadius = 12
      headerView.layer.shadowOpacity = 0.5
    }
  }
  
  private func updateHeaderConstraints() {
    guard isShowingHeader, let headerContent = headerView.subviews.first else { return }
    adjustHeaderPositioningConstraint()
    adjustHeaderHeightConstraint(toFit: headerContent)
    view.setNeedsUpdateConstraints()
  }
  
  private func adjustHeaderPositioningConstraint() {
    if cardIsNextToMap(in: traitCollection) {
      headerViewTopConstraint.constant = topOverlap + Constants.floatingHeaderTopMargin
    } else {
      headerViewTopConstraint.constant = 0
    }
  }
  
  private func adjustHeaderHeightConstraint(toFit content: UIView) {
    let contentSize = content.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    if cardIsNextToMap(in: traitCollection) {
      headerViewHeightConstraint.constant = contentSize.height
    } else {
      headerViewHeightConstraint.constant = contentSize.height + topOverlap
    }
  }
  
  fileprivate func showHeader(content: TGHeaderView, animated: Bool) {
    // update the header content.
    overwriteHeaderContent(with: content)
   
    // adjust constraints
    updateHeaderStyle()
    adjustHeaderPositioningConstraint()
    adjustHeaderHeightConstraint(toFit: content)
    
    // notify UIKit the header's contraints need to be updated.
    view.setNeedsUpdateConstraints()
    
    // An extended sheet needs to make space for the header
    if !isTransitioningCards {
      applySheetPosition(animated: animated)
    }

    // animate in
    let spring = cardIsNextToMap(in: traitCollection)
    UIView.animate(
      withDuration: animated ? Constants.tapAnimationDuration : 0,
      delay: 0,
      usingSpringWithDamping: spring ? 0.8 : 1,
      initialSpringVelocity: 0,
      options: [.curveEaseOut],
      animations: {
        self.updateStatusBar(headerIsVisible: true, preferredStyle: content.preferredStatusBarStyle)
        self.view.layoutIfNeeded()
      },
      completion: nil
    )
  }
  
  fileprivate func hideHeader(animated: Bool) {
    headerViewTopConstraint.constant = headerView.frame.height * -1
    view.setNeedsUpdateConstraints()
    if !isTransitioningCards {
      applySheetPosition(animated: animated)
    }
    
    guard animated else {
      self.view.layoutIfNeeded()
      self.headerView.subviews.forEach { $0.removeFromSuperview() }
      self.updateStatusBar(headerIsVisible: false)
      return
    }

    UIView.animate(
      withDuration: Constants.tapAnimationDuration,
      delay: 0,
      usingSpringWithDamping: 0.8,
      initialSpringVelocity: 0,
      options: [.curveEaseIn],
      animations: {
        self.view.layoutIfNeeded()
        self.updateStatusBar(headerIsVisible: false)
      },
      completion: { finished in
        guard finished else { return }
        self.headerView.subviews.forEach { $0.removeFromSuperview() }
      }
    )
  }
  
  fileprivate func overwriteHeaderContent(with content: UIView) {
    headerView.subviews.forEach { $0.removeFromSuperview() }
    content.translatesAutoresizingMaskIntoConstraints = false
    headerView.addSubview(content)
    let contentSize = content.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    content.heightAnchor.constraint(equalToConstant: contentSize.height).isActive = true
    content.leadingAnchor.constraint(equalTo: headerView.leadingAnchor).isActive = true
    content.trailingAnchor.constraint(equalTo: headerView.trailingAnchor).isActive = true
    content.bottomAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
  }
  
  private func updateStatusBar(headerIsVisible: Bool, preferredStyle: UIStatusBarStyle? = nil) {
    let headerExtendsToTop = !cardIsNextToMap(in: traitCollection)
    let headerCoversStatusBar = headerIsVisible && headerExtendsToTop
    
    statusBarBlurView.alpha = headerCoversStatusBar ? 0 : 1

    if headerIsVisible, let newStyle = preferredStyle {
      headerStatusBarStyle = newStyle
    } else if !headerIsVisible {
      headerStatusBarStyle = nil
    }

#if !os(visionOS)
    setNeedsStatusBarAppearanceUpdate()
#endif
  }
  
}

// MARK: - UIGestureRecognizerDelegate

extension TGCardViewController: UIGestureRecognizerDelegate {
  
  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    if cardTapper == gestureRecognizer {
      // Only intercept any taps on the title.
      // This is so that the tapper doesn't interfere with, say, taps on a table view.
      guard let view = topCardView else { return false }
      let touchPoint = touch.location(in: view)
      return touchPoint.y < view.headerHeight(for: cardPosition) && view.interactiveTitleContains(touchPoint) == false
      
    } else if mapShadowTapper == gestureRecognizer {
      // Only intercept any taps when in the expanded state.
      // This is so that the tapper doesn't interfere with taps on the map
      switch cardPosition {
      case .extended:             return true
      case .collapsed, .peaking:  return false
      }
      
    } else if gestureRecognizer == panner {
      // Don't allow panning if the card is extended and there's a refresh
      // control
      guard let innerScroll = topCardView?.contentScrollView else { return true }
      return cardWrapperDesiredTopConstraint.constant > extendedMinY
        || innerScroll.refreshControl == nil
        || touch.location(in: innerScroll).y <= 0
      
    } else {
      return true
    }
  }
  
  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
    
    // As per UIKit defaults, no two gesture recognisers should fire together
    guard panningAllowed, gestureRecognizer == panner else { return false }
    
    if let scrollView = topCardView?.contentScrollView, other == scrollView.panGestureRecognizer {
      // This does special handling for dragging down the card by its scroll view content
      return pannerShouldRecognizeSimultaneouslyWithPanner(in: scrollView)
    
    } else if let pager = (topCardView as? TGPageCardView)?.pager, other == pager.panGestureRecognizer {
      // When our panner fires, block panning of the page card
      return false
    
    } else {
      // We don't want to interfere with any existing horizontal swipes, e.g., swipe to delete
      // We cancel our gesture recogniser then in `handlePan`.
      let velocity = panner.velocity(in: cardWrapperContent)
      let swipeHorizontally = abs(velocity.x) > abs(velocity.y)
      return swipeHorizontally
    }
  }
  
  private func pannerShouldRecognizeSimultaneouslyWithPanner(in scrollView: UIScrollView) -> Bool {
    let direction = Direction(ofVelocity: panner.velocity(in: cardWrapperContent))
    
    let velocity = panner.velocity(in: cardWrapperContent)
    let swipeHorizontally = abs(velocity.x) > abs(velocity.y)
    
    let y = cardWrapperDesiredTopConstraint.constant
    
    switch (y, scrollView.contentOffset.y, direction, swipeHorizontally) {
    case (collapsedMinY, _, _, _), (peakY, _, _, _):
      // we don't care about any other conditions, as long as the top card is at
      // one of these two positions, scrolling is disabled.
      scrollView.isScrollEnabled = false
      
    case (extendedMinY, 0, _, true):
      // while the top card is at the extended position, we are more interested
      // in finding out first if the user is panning horizontally, that is,
      // paging between pages. If they are, don't make any changes.
      break
      
    case (extendedMinY, 0, .down, _):
      // if the top card is at the extended position with its content scroll view
      // already scrolled to the top, and the user is scrolling down, scrolling is
      // disabled, so the card can be moved down to peak/collapsed position. Note,
      // this is tested after looking for horizontally swiping. If the order is
      // reversed, we could end up in a situation where a scoll view needs a 2nd
      // scroll to actually scroll up due to horizontally scrolling also carries
      // with it a vertical component.
      scrollView.isScrollEnabled = false
      
    default:
      // scrolling is enabled when the top card is at the extended position and
      // the user is scrolling up. It's also enabled when user scrolls down and
      // the scroll view isn't at its top, i.e., its content offset on the y axis
      // isn't zero.
      scrollView.isScrollEnabled = true
    }
    
    // iOS 26 and up automatically handles the dragging the outer card while
    // we do the inner pan. So we can let it pass. This works in combination
    // with the early exist in handleInnerPan.
    if #available(iOS 26.0, *) {
      return scrollView.contentOffset.y <= 0
    } else {
      return false
    }
  }
  
}


// MARK: - TGCardDelegate

extension TGCardViewController: TGCardDelegate {
  
  public func mapManagerDidChange(old: TGCompatibleMapManager?, for card: TGCard) {
    guard card === topCard else { return }
    
    old?.cleanUp(mapView, animated: true)
    card.mapManager?.takeCharge(of: mapView, edgePadding: mapEdgePadding(for: cardPosition), animated: true)
  }
  
  public func contentScrollViewDidChange(old: UIScrollView?, for card: TGCard) {
    if card === topCard {
      updateSheetContentScrollView()
    }
    guard panningAllowed, card === topCard, let view = topCardView else { return }
    
    old?.panGestureRecognizer.removeTarget(self, action: nil)
    view.contentScrollView?.panGestureRecognizer.addTarget(self, action: #selector(handleInnerPan(_:)))
  }
  
}


// MARK: - VoiceOver

extension TGCardViewController {
  
  @MainActor
  override open func accessibilityPerformEscape() -> Bool {
    return popMaybe()
  }
  
  private func monitorVoiceOverStatus() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(updateForVoiceOverStatusChange),
      name: UIAccessibility.voiceOverStatusDidChangeNotification,
      object: nil
    )

#if !os(visionOS)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(updateForVoiceOverFocusChange),
      name: UIAccessibility.elementFocusedNotification,
      object: nil
    )
#endif
  }
  
  @objc
  private func updateForVoiceOverStatusChange() {
    updateCardScrolling(allow: cardPosition == .extended, view: topCardView)
  }
  
#if !os(visionOS)
  @objc
  private func updateForVoiceOverFocusChange(notification: Notification) {
    guard let selection = notification.userInfo?[UIAccessibility.focusedElementUserInfoKey] as? UIAccessibilityElement else { return }
    
    // When the card is not in extended, and you use voice over to navigate
    // through the elements, you can go beyond the screens space if you're near
    // the end of a scroll view. If this happens, we switch to extended state
    // to make the focus visible on the card. This mirrors Apple Maps.
    if selection.accessibilityFrame.maxY > UIScreen.main.bounds.maxY, cardPosition != .extended {
      switchTo(.extended, direction: .up, animated: true)
    }
  }
#endif
  
  private func buildCardHandleAccessibilityActions() -> [UIAccessibilityCustomAction] {
    return [
      UIAccessibilityCustomAction(
        name: NSLocalizedString("Collapse", bundle: TGCardViewController.bundle, comment: "Accessibility action to collapse card"),
        target: self, selector: #selector(collapse)
      ),
      UIAccessibilityCustomAction(
        name: NSLocalizedString("Expand", bundle: TGCardViewController.bundle, comment: "Accessibility action to expand card"),
        target: self, selector: #selector(expand)
      )
    ]
  }
  
  @objc
  @discardableResult
  private func expand() -> Bool {
    let desired: TGCardPosition
    switch cardPosition {
    case (.extended):  return false // tapping when extended does nothing
    case (.peaking):   desired = .extended
    case (.collapsed): desired = .peaking
    }
    
    switchTo(desired, direction: .up, animated: true)
    return true
  }
  
  @objc
  @discardableResult
  private func collapse() -> Bool {
    let desired: TGCardPosition
    switch cardPosition {
    case (.extended):  desired = .peaking
    case (.peaking):   desired = .collapsed
    case (.collapsed): return false // tapping when extended does nothing
    }
    
    switchTo(desired, direction: .down, animated: true)
    return true
  }

  private func updateCardHandleAccessibility(handle: TGGrabHandleView, position: TGCardPosition) {
    handle.isAccessibilityElement = true
    handle.accessibilityCustomActions = buildCardHandleAccessibilityActions()
    
    switch position {
    case .collapsed:
      handle.accessibilityLabel = NSLocalizedString(
        "Card controller minimised", bundle: TGCardViewController.bundle,
        comment: "Card handle accessibility description for collapsed state"
      )
      
    case .extended:
      handle.accessibilityLabel = NSLocalizedString(
        "Card controller full screen", bundle: TGCardViewController.bundle,
        comment: "Card handle accessibility description for collapsed state"
      )

    case .peaking:
      handle.accessibilityLabel = NSLocalizedString(
        "Card controller half screen", bundle: TGCardViewController.bundle,
        comment: "Card handle accessibility description for collapsed state"
      )
    }
    
    handle.accessibilityHint = NSLocalizedString(
      "Adjust the size of the card overlaying the map.", bundle: TGCardViewController.bundle,
      comment: ""
    )
  }
  
}

// MARK: - Keyboard

extension TGCardViewController {
  
  private func updateResponderChainForNewTopCard() {
    // We make the card itself the first responder, as the responder
    // chain otherwise starts with our view and then down from there to this
    // controller

    topCard?.becomeFirstResponder()
  }
  
  open override var canBecomeFirstResponder: Bool {
    return true
  }
  
  open override var keyCommands: [UIKeyCommand]? {
    var commands = [
      UIKeyCommand(
        action: #selector(expand), input: UIKeyCommand.inputUpArrow, modifierFlags: .control,
        discoverabilityTitle: NSLocalizedString(
          "Expand card", bundle: TGCardViewController.bundle,
          comment: "Discovery hint for keyboard shortcuts"
        )
      ),
      UIKeyCommand(
        action: #selector(collapse), input: UIKeyCommand.inputDownArrow, modifierFlags: .control,
        discoverabilityTitle: NSLocalizedString(
          "Collapse card", bundle: TGCardViewController.bundle,
          comment: "Discovery hint for keyboard shortcuts"
        )
      ),
    ]
    
    if presentedOverlayViewController != nil {
      #if targetEnvironment(macCatalyst)
      commands.append(
        UIKeyCommand(
          input: "d", modifierFlags: .command, action: #selector(dismissPresentee)
      ))

      commands.append(
        UIKeyCommand(
          input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(dismissPresentee)
      ))
      #else
      commands.append(
        UIKeyCommand(
          action: #selector(dismissPresentee), input: "w", modifierFlags: .command,
          discoverabilityTitle: NSLocalizedString(
            "Dismiss", bundle: TGCardViewController.bundle,
            comment: "Discovery hint for keyboard shortcuts"
          )
      ))
      
      commands.append(
        UIKeyCommand(
          input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(dismissPresentee)
      ))
      #endif

    } else if topCard != nil, cards.count > 1 || delegate != nil {
      commands.append(
        UIKeyCommand(
          action: #selector(pop), input: "[", modifierFlags: .command,
          discoverabilityTitle: NSLocalizedString(
            "Back to previous card", bundle: TGCardViewController.bundle,
            comment: "Discovery hint for keyboard shortcuts"
          )
      ))
    }
    
    return commands
  }
  
  @objc func dismissPresentee() {
    dismiss(animated: true)
  }
}

extension UIResponder {
  func responderChain() -> String {
    guard let next = next else {
      return String(describing: self)
    }
    return String(describing: self) + "\n -> " + next.responderChain()
  }
}

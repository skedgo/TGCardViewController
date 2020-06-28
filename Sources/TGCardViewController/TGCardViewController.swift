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

public protocol TGCardViewControllerDelegate: class {
  func requestsDismissal(for controller: TGCardViewController)
}

/// The root view controller for using cards in your app.
///
///
/// ## How to use this in your app
///
/// First, create a subclass, then use this in your your storyboard.
///
/// Second, In your subclass override `init(coder:)` as follows, so that the
/// instance from the storyboard isn’t used, but instead the pre-configured one
/// from `TGCardViewController.xib`:
///
/// ```
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
/// ```
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
///    for `init(coder:). The typical approach here is to save and restore the
///    basic information, to then call your usual `init` methods on the cards.
open class TGCardViewController: UIViewController {
  
  fileprivate enum Constants {
    /// The minimum number of points between the status bar and the
    /// top of the card to keep a bit of the map always showing through.
    fileprivate static let minMapSpace: CGFloat = 50
    
    fileprivate static let minMapSpaceWithHomeIndicator: CGFloat = 25
    
    fileprivate static let pushAnimationDuration = 0.25

    /// The minimum seconds for snapping after the user panned the top card.
    /// Good to be a little higher than others as it'll spring.
    fileprivate static let snapAnimationMinimumDuration = 0.4

    /// The seconds for switching the top card to its new location after tapping it.
    fileprivate static let tapAnimationDuration = 0.25

    fileprivate static let mapShadowVisibleAlpha: CGFloat = 0.25
    
    fileprivate static let floatingHeaderTopMargin: CGFloat = 20
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
  
  public static var bundle = Bundle.module
  
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
  
  @IBOutlet weak var headerView: UIView!
  @IBOutlet weak var mapViewWrapper: UIView!
  public weak var mapView: UIView!
  @IBOutlet weak var mapShadow: UIView!
  @IBOutlet weak var cardWrapperShadow: UIView!
  @IBOutlet public weak var cardWrapperContent: UIView!
  fileprivate weak var cardTransitionShadow: UIView?
  @IBOutlet weak var statusBarBlurView: UIVisualEffectView!
  @IBOutlet weak var topFloatingView: UIStackView!
  @IBOutlet weak var bottomFloatingView: UIStackView!
  @IBOutlet weak var topFloatingViewWrapper: UIVisualEffectView!
  @IBOutlet weak var bottomFloatingViewWrapper: UIVisualEffectView!
  @IBOutlet weak var sidebarBackground: UIView!
  @IBOutlet weak var sidebarVisualEffectView: UIVisualEffectView!
  @IBOutlet weak var sidebarSeparator: UIView!
  
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
  @IBOutlet weak var topFloatingViewTrailingToSuperConstraint: NSLayoutConstraint!
  @IBOutlet weak var topFloatingViewTrailingToSafeAreaConstraint: NSLayoutConstraint!
  @IBOutlet weak var bottomFloatingViewTrailingToSuperConstraint: NSLayoutConstraint!
  @IBOutlet weak var bottomFloatingViewTrailingToSafeAreaConstraint: NSLayoutConstraint!
  @IBOutlet weak var bottomFloatingViewBottomConstraint: NSLayoutConstraint! // only active in landscape
  
  // Dynamic constraints
  @IBOutlet weak var statusBarBlurHeightConstraint: NSLayoutConstraint!

  var panner: UIPanGestureRecognizer!
  var cardTapper: UITapGestureRecognizer!
  var mapShadowTapper: UITapGestureRecognizer!
  var edgePanner: UIScreenEdgePanGestureRecognizer!
  
  /// Builder that determines what kind of map to use. The builder's
  /// `buildMapView()` method will be once initially, and the map instance will
  /// then be passed to the card's `mapManager` via the
  /// `takeCharge(of:edgePadding:animated:)` and `cleanUp(_:animated:)` calls.
  ///
  /// @default: An instance of `TGMapKitBuilder`, i.e., using Apple's MapKit.
  public var builder: TGCompatibleMapBuilder = TGMapKitBuilder()
  
  /// The card to display at the root. If you have more than one, use `initialCards`
  public var rootCard: TGCard? {
    get { initialCards.first }
    set { initialCards = [newValue].compactMap { $0 } }
  }

  /// The initial card stack to display
  public var initialCards: [TGCard] = []
  
  private var didAddInitialCards = false
  
  /// The style that's applied to the cards' top and bottom map tool
  /// bar itms.
  ///
  /// @default: `TGButtonStyle.roundedRect`
  public var buttonStyle: TGButtonStyle = .roundedRect {
    didSet {
      switch buttonStyle {
      case .roundedRect:
        topFloatingViewWrapper.layer.cornerRadius = 8
        bottomFloatingViewWrapper.layer.cornerRadius = 8
      case .circle:
        topFloatingViewWrapper.layer.cornerRadius = topFloatingViewWrapper.frame.width / 2
        bottomFloatingViewWrapper.layer.cornerRadius = bottomFloatingViewWrapper.frame.height / 2
      case .none:
        topFloatingViewWrapper.layer.cornerRadius = 0
        bottomFloatingViewWrapper.layer.cornerRadius = 0
      }
    }
  }
  
  /// Position of current location button
  ///
  /// @default: `top`
  public var locationButtonPosition: TGButtonPosition = .top
  
  private var defaultButtons: [UIView]!

  /// This is just for debugging issues where it helps to disable
  /// everything related to panning. Otherwise it should always
  /// be set to `true`.
  private let panningAllowed = true
  
  private var isDraggingCard = false
  
  fileprivate var isVisible = false
  
  /// To stop popping too quickly which messes things up
  private var isPopping = false
  
  fileprivate var previousCardPosition: TGCardPosition?
  
  fileprivate var cards = [(card: TGCard, lastPosition: TGCardPosition, view: TGCardView?)]()

  // Before pushing a header that extends to the top
  private var previousStatusBarStyle: UIStatusBarStyle?
  private var headerStatusBarStyle: UIStatusBarStyle?

  // MARK: - UIViewController
  
  open override func awakeFromNib() {
    super.awakeFromNib()
    
    self.restorationIdentifier = "CardViewController"
  }
  
  open override var preferredStatusBarStyle: UIStatusBarStyle {
    return headerStatusBarStyle ?? previousStatusBarStyle ?? .default
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  override open func viewDidLoad() {
    super.viewDidLoad()
    
    // mode-specific styling
    TGCornerView.roundedCorners                   = mode == .floating
    cardWrapperDynamicLeadingConstraint.isActive  = mode == .floating
    cardWrapperStaticLeadingConstraint.isActive   = mode == .sidebar
    toggleCardWrappers(hide: true)
    
    if #available(iOS 13.0, *) {
      sidebarSeparator.backgroundColor = .separator
      sidebarVisualEffectView.effect = UIBlurEffect(style: .systemThickMaterial)
    } else {
      sidebarSeparator.backgroundColor = UIColor(white: 1.0, alpha: 0.85)
    }
    
    let mapView = builder.buildMapView()
    mapViewWrapper.addSubview(mapView)
    mapView.topAnchor.constraint(equalTo: mapViewWrapper.topAnchor).isActive = true
    mapView.trailingAnchor.constraint(equalTo: mapViewWrapper.trailingAnchor).isActive = true
    mapView.bottomAnchor.constraint(equalTo: mapViewWrapper.bottomAnchor).isActive = true
    mapView.leadingAnchor.constraint(equalTo: mapViewWrapper.leadingAnchor).isActive = true
    mapView.translatesAutoresizingMaskIntoConstraints = false
    self.mapView = mapView

    setupGestures()
    
    // Create the default buttons
    self.defaultButtons = [
        builder.buildUserTrackingButton(for: mapView),
        builder.buildCompassButton(for: mapView)
      ].compactMap { $0 }
    
    // Setting up additional constraints
    cardWrapperHeightConstraint.constant = extendedMinY * -1
    cardWrapperMinOverlapTopConstraint.constant = 0
    
    // Hide the bars at first
    hideHeader(animated: false)

    // Collapse card at first
    cardWrapperDesiredTopConstraint.constant = collapsedMinY
    
    // Add a bit of a shadow behind card.
    if mode == .floating {
      cardWrapperShadow.layer.shadowColor = UIColor.black.cgColor
      cardWrapperShadow.layer.shadowOffset = .zero
      cardWrapperShadow.layer.shadowRadius = 12
      cardWrapperShadow.layer.shadowOpacity = 0.5
    }
    
    monitorVoiceOverStatus()
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
    
    // Edge panning to go back
    let edgePanner = UIScreenEdgePanGestureRecognizer()
    edgePanner.addTarget(self, action: #selector(popMaybe))
    edgePanner.isEnabled = mode == .floating
    edgePanner.edges = .left
    view.addGestureRecognizer(edgePanner)
    self.edgePanner = edgePanner
  }
  
  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if view.superview != nil {
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
      cardWrapperDesiredTopConstraint.constant = distanceFromHeaderView
    }
    
    // Now is the time to restore
    if let position = restoredCardPosition {
      moveCard(to: position, animated: false)
      
      // During the state restoration process, cards are pushed and
      // for those with header views, they will be built, position
      // and height calculated. However, the view controller's `view`
      // may not have the correct safe area inset at this point.
      // We, thus, adjust the position and height here so correct
      // safe area insets are used in the calculations.
      updateHeaderConstraints()
      
      restoredCardPosition = nil
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
  }
  
  override open func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    topCard?.willDisappear(animated: animated)
    isVisible = false
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
  
  override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    
    cardWrapperHeightConstraint.constant = extendedMinY * -1
    
    // When trait collection changes, try to keep the same card position
    if let previous = previousCardPosition {
      // Note: Ideally, we'd determine the direction by whether the available
      // height of VC increased or decreased, but for simplicity just using
      // `up` is fine.
      cardWrapperDesiredTopConstraint.constant = cardLocation(forDesired: previous, direction: .up).y
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
  }
  
  private func updateCardScrolling(allow: Bool, view: TGCardView?) {
    let allowScrolling = allow || UIAccessibility.isVoiceOverRunning || mode == .sidebar
    view?.allowContentScrolling(allowScrolling)
  }
  
  open override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    if view.superview != nil {
      if !didAddInitialCards {
        initialCards.forEach { push($0, animated: false) }
        didAddInitialCards = true
      }
      
      fixPositioning()
    }
  }
  
  private func fixPositioning() {
    statusBarBlurHeightConstraint.constant = topOverlap
    topCardView?.adjustContentAlpha(to: cardPosition == .collapsed ? 0 : 1)
    updateFloatingViewsConstraints()
    
    if !mapView.frame.isEmpty {
      let edgePadding = mapEdgePadding(for: cardPosition)
      if let mapManager = topCard?.mapManager, mapManager.edgePadding != edgePadding {
        mapManager.edgePadding = edgePadding
      }
    }
  }
  
  override open func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  // MARK: - UIStateRestoring
  
  private var restoredCardPosition: TGCardPosition?
  private var restoredCards: [(card: TGCard, lastPosition: TGCardPosition)]?
  
  private struct RestorableCard: Codable {
    let cardData: Data
    let lastPosition: TGCardPosition
  }

  open override func encodeRestorableState(with coder: NSCoder) {
    defer { super.encodeRestorableState(with: coder) }
    
    coder.encode(cardPosition.rawValue, forKey: "cardPosition")

    // We encode all the cards, even if they might not be able to get restored
    // later. We filter that out when decoding, later.
    // We do this funky method way here of using codable and having data in
    // there, so that we can later selectively decode some of them, even if
    // others fail to get decoded.
    let cardInfos = cards
      .map { card, position, _ in (NSKeyedArchiver.archivedData(withRootObject: card), position) }
      .map(RestorableCard.init)
    let cardData = try? PropertyListEncoder().encode(cardInfos)
    coder.encode(cardData, forKey: "cardData")
  }

  open override func decodeRestorableState(with coder: NSCoder) {
    defer { super.decodeRestorableState(with: coder) }

    if let rawPosition = coder.decodeObject(of: NSString.self, forKey: "cardPosition") {
      restoredCardPosition = TGCardPosition(rawValue: rawPosition as String)
    }
    
    // Decode the stack up to the first card failing, e.g., returning `nil`
    // from its `init(coder:)` method.
    if let cardData = coder.decodeObject(forKey: "cardData") as? Data,
       let cardInfos = try? PropertyListDecoder().decode([RestorableCard].self, from: cardData) {
      var successfullyRestored = [(card: TGCard, lastPosition: TGCardPosition)]()
      for restorable in cardInfos {
        guard let card = NSKeyedUnarchiver.unarchiveObject(with: restorable.cardData) as? TGCard else {
          break // don't go any further in the stack
        }
        successfullyRestored.append((card: card, lastPosition: restorable.lastPosition))
      }
      self.restoredCards = successfullyRestored
    }
    if let cards = coder.decodeObject(of: [TGCard.self], forKey: "cards") as? [TGCard] {
      self.restoredCards = cards.map { ($0, .peaking) }
    }
  }
  
  open override func applicationFinishedRestoringState() {
    super.applicationFinishedRestoringState()
    
    // Now add the content
    if let toRestore = restoredCards {
      for (index, element) in toRestore.enumerated() {
        guard rootCard == nil || index > 0 else { continue }
        push(element.card, animated: false)
      }
      restoredCards = nil
    }
  }
  
  
  // MARK: - Card positioning
  
  /// The current card position, inferred from the current drag position of the card
  public var cardPosition: TGCardPosition {
    guard mode == .floating else { return .extended }
    
    let cardY = cardWrapperDesiredTopConstraint.constant
    
    switch (cardY, traitCollection.verticalSizeClass) {
    case (0..<peakY, _):                      return .extended
    case (peakY..<collapsedMinY, .regular):   return .peaking
    default:                                  return .collapsed
    }
  }
  
  fileprivate var extendedMinY: CGFloat {
    var value = topOverlap
    
    if let navigationBar = navigationController?.navigationBar {
      value += navigationBar.frame.height
    }
    if #available(iOS 11.0, *), mode == .floating, view.safeAreaInsets.bottom > 0 {
      value += Constants.minMapSpaceWithHomeIndicator
    } else if mode == .floating {
      value += Constants.minMapSpace
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
    if #available(iOS 11, *) {
      return view.safeAreaInsets.top
    } else {
      return topLayoutGuide.length
    }
  }
  
  /// The edge padding for the map that map managers should use
  /// to determine the zoom and scroll position of the map.
  ///
  /// - Note: This is the card's overlap for the collapsed and peaking
  ///         card positions, and capped at the peaking card position
  ///         for the extended overlap (to avoid only having a tiny
  ///         map area to work with).
  fileprivate func mapEdgePadding(for position: TGCardPosition) -> UIEdgeInsets {
    assert(mapView.frame.isEmpty == false, "Don't call this before we have a map view frame.")
    
    let bottomOverlap: CGFloat
    let leftOverlap: CGFloat
    
    if cardIsNextToMap(in: traitCollection) {
      // The map is to the right of the card, which we account for when not collapsed
      let ignoreCard = position == .collapsed && traitCollection.verticalSizeClass == .regular
      leftOverlap = ignoreCard ? 0 : cardWrapperShadow.frame.maxX
      bottomOverlap = 0
    } else {
      // Map is always between the top and the cad
      leftOverlap = 0
      let cardY: CGFloat
      switch position {
      case .extended, .peaking: cardY = peakY
      case .collapsed:          cardY = collapsedMinY - 75 // not entirely true, but close enough
      }
      
      // We call this method at times where the map view hasn't been resized yet. We
      // guess the height by just taking the larger side since the card is not next
      // to the map, meaning we're in portrait.
      let height = max(mapView.frame.width, mapView.frame.height)
      
      bottomOverlap = height - cardY
    }
    
    return UIEdgeInsets(top: topOverlap, left: leftOverlap, bottom: bottomOverlap, right: 0)
  }
  
  /// Call this whenever the card position changes to properly configure the map shadow
  ///
  /// - Parameter position: New card position
  fileprivate func updateMapShadow(for position: TGCardPosition) {
    mapShadow.alpha = position == .extended ? Constants.mapShadowVisibleAlpha : 0
    mapShadow.isUserInteractionEnabled = position == .extended
  }
  
  private func toggleCardWrappers(hide: Bool, prepareOnly: Bool = false) {
    if mode == .sidebar {
      sidebarBackground.alpha = hide ? 0 : 1
    } else {
      sidebarBackground.alpha = 0
    }
    cardWrapperShadow.alpha = hide ? 0 : 1

    if !prepareOnly {
      if mode == .sidebar {
        sidebarBackground.isHidden = hide
      } else {
        sidebarBackground.isHidden = true
      }
      cardWrapperShadow.isHidden = hide
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
  
  private var topCardView: TGCardView? {
    return cards.last?.view
  }
  
}

// MARK: - Card stack management

extension TGCardViewController {
  
  fileprivate func cardLocation(forDesired desired: TGCardPosition?, direction: Direction)
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
    // Set the controller on the top card earlier, because we may want
    // to ask the card to do something on willAppear, e.g., show sticky 
    // bar, which requires access to this property.
    top.controller = self
    
    // 1. Determine where the new card will go
    let forceExtended = (top.mapManager == nil)
    let animateTo = cardLocation(forDesired: forceExtended ? .extended : top.initialPosition, direction: .down)

    // 2. Updating card logic and informing of transition
    let oldTop = cardWithView(atIndex: cards.count - 1)
    let notify = isVisible
    if notify {
      oldTop?.card.willDisappear(animated: animated)
    }
    
    if let oldTop = oldTop {
      cards.removeLast()
      cards.append( (oldTop.card, cardPosition, oldTop.view) )
    }
    
    // 3. Create and configure the new view
    
    // Copying style from old card to new card MUST be called before
    // new card builds its card view.
    if let oldCard = oldTop?.card, copyStyle {
      oldCard.copyStyling(to: top)
    }
    
    let cardView = top.buildCardView()
    cards.append( (top, animateTo.position, cardView) )
        
    if let cardView = cardView {
      cardView.dismissButton?.addTarget(self, action: #selector(closeTapped(sender:)), for: .touchUpInside)
      let showClose = (delegate != nil || cards.count > 1) && top.showCloseButton
      cardView.updateDismissButton(show: showClose, isSpringLoaded: navigationButtonsAreSpringLoaded)
      
      // On device with home indicator, we want only the header part of a card view is
      // visible when the card is in collapsed state. If we don't adjust the alpha as
      // below, since the card view is placed on the top of the bottom safe layout guide,
      // which is an additional 34px on iPhone X, we will see part of the card content
      // coming through.
      cardView.adjustContentAlpha(to: animateTo.position == .collapsed ? 0 : 1)
      
      // This allows us to continuously pull down the card view while its
      // content is scrolled to the top. Note this only applies when the
      // card isn't being forced into the extended position.
      if !forceExtended && panningAllowed {
        cardView.contentScrollView?.panGestureRecognizer.addTarget(self, action: #selector(handleInnerPan(_:)))
      }
    
      // 4. Place the new view coming, preparing to animate in from the bottom
      cardView.frame = cardWrapperContent.bounds
      if animated {
        cardView.frame.origin.y = cardWrapperContent.frame.maxY
      }
      cardWrapperContent.addSubview(cardView)
      
      // Give AutoLayout a nudge to layout the card view, now that we have
      // the right height. This is so that we can use `cardView.headerHeight`.
      cardView.setNeedsUpdateConstraints()
      cardView.layoutIfNeeded()
    }
    
    // 5. Special handling of when the new top card has no map content
    updatePannerInteractivity()
    updateGrabHandleVisibility()
    
    // 6. Set new position of the wrapper
    cardWrapperDesiredTopConstraint.constant = animateTo.y
    if let cardView = cardView {
      cardWrapperMinOverlapTopConstraint.constant = cardView.headerHeight(for: .collapsed)
    }
    
    let header = top.buildHeaderView()
    if let header = header {
      // Keep this to restore it later when hiding the header
      if previousStatusBarStyle == nil {
        previousStatusBarStyle = preferredStatusBarStyle
      }
      
      header.closeButton?.addTarget(self, action: #selector(closeTapped(sender:)), for: .touchUpInside)
      if #available(iOS 11.0, *) {
        header.closeButton?.isSpringLoaded = navigationButtonsAreSpringLoaded
        header.rightButton?.isSpringLoaded = navigationButtonsAreSpringLoaded
      }
      showHeader(content: header, animated: animated)
    } else if isShowingHeader {
      hideHeader(animated: animated)
    }
    
    // Notify that we have completed building the card view and its header view.
    top.cardView = cardView
    top.didBuild(cardView: cardView, headerView: header)
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

    // Incoming card has its own top and bottom floating views.
    updateFloatingViewsContent()
    
    // Since the header view may be animated in & out, it's best to update the
    // height of the card's content wrapper.
    updateContentWrapperHeightConstraint()
    
    view.setNeedsUpdateConstraints()
    
    // 8. Do the transition, optionally animated
    // We insert a temporary shadow underneath the new top view and above the
    // old. Only do that if the previous transition completed, i.e., we didn't
    // already have such a shadow.
    
    if oldTop != nil && animated && cardTransitionShadow == nil, let cardView = cardView {
      let shadow = TGCornerView(frame: cardWrapperContent.bounds)
      shadow.frame.size.height += 50 // for bounciness
      shadow.backgroundColor = .black
      shadow.alpha = 0
      cardWrapperContent.insertSubview(shadow, belowSubview: cardView)
      cardTransitionShadow = shadow
    }
    
    let cardAnimations = {
      self.toggleCardWrappers(hide: cardView == nil, prepareOnly: true)

      guard let cardView = cardView else { return }
      self.updateMapShadow(for: animateTo.position)
      cardView.frame = self.cardWrapperContent.bounds
      self.cardTransitionShadow?.alpha = 0.15
    }
    if self.mode != .floating {
      cardAnimations()
      oldTop?.view?.alpha = 0
    }

    UIView.animate(
      withDuration: animated ? Constants.pushAnimationDuration : 0,
      delay: 0,
      usingSpringWithDamping: 0.75,
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
        self.updateCardScrolling(allow: animateTo.position == .extended, view: cardView)
        self.previousCardPosition = animateTo.position
        oldTop?.view?.alpha = 0
        if notify {
          oldTop?.card.didDisappear(animated: animated)
          top.didAppear(animated: animated)
          top.didMove(to: animateTo.position, animated: animated)
        }
        self.cardTransitionShadow?.removeFromSuperview()
        self.updateCardHandleAccessibility(for: animateTo.position)
        self.updateResponderChainForNewTopCard()
        self.toggleCardWrappers(hide: cardView == nil)
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
    
    // 4. Determine and set new position of the card wrapper
    newTop?.view?.alpha = 1

    // We only animate to the previous position if the card obscures the map
    let animateTo: TGCardPosition
    let forceExtended = newTop?.card.mapManager == nil
    if forceExtended || !cardIsNextToMap(in: traitCollection) {
      let target = cardLocation(forDesired: forceExtended ? .extended : newTop?.lastPosition, direction: .down)
      cardWrapperDesiredTopConstraint.constant = target.y
      animateTo = target.position
    } else {
      animateTo = cardPosition
    }
    if let new = newTop, let newView = new.view {
      cardWrapperMinOverlapTopConstraint.constant = newView.headerHeight(for: new.lastPosition)
    } else {
      cardWrapperMinOverlapTopConstraint.constant = 0
    }
    
    // TODO: It'd be better if we didn't have to build the header again, but could
    //       just re-use it from the previous push. 
    // See https://gitlab.com/SkedGo/tripgo-cards-ios/issues/7.
    if let header = newTop?.card.buildHeaderView() {
      showHeader(content: header, animated: animated)
    } else if isShowingHeader {
      hideHeader(animated: animated)
    }
    
    // Since the header may be animated in and out, it's safer to update the height
    // of the card's content wrapper.
    updateContentWrapperHeightConstraint()
    
    // Before animating views in and out, restore both top and bottom floating views
    // to previous card's values. Note that, we force a clean up of floating views
    // because the popping card may have added views that are only applicable to it-
    // self.
    updateFloatingViewsContent()
    
    // Notify that constraints need to be updated in the next cycle.
    view.setNeedsUpdateConstraints()

    // 5. Do the transition, optionally animated.
    // We animate the view moving back down to the bottom
    // we also temporarily insert a shadow view again, if there's a card below    
    if animated, newTop != nil, cardTransitionShadow == nil, let topView = topView {
      let shadow = TGCornerView(frame: cardWrapperContent.bounds)
      shadow.backgroundColor = .black
      shadow.alpha = 0.15
      cardWrapperContent.insertSubview(shadow, belowSubview: topView)
      cardTransitionShadow = shadow
    }
    
    let cardAnimations = {
      self.toggleCardWrappers(hide: newTop?.view == nil, prepareOnly: true)

      self.updateMapShadow(for: animateTo)
      topView?.frame.origin.y = self.cardWrapperContent.frame.maxY
      self.cardTransitionShadow?.alpha = 0
      newTop?.view?.adjustContentAlpha(to: animateTo == .collapsed ? 0 : 1)
    }
    
    if mode != .floating {
      cardAnimations()
      topView?.alpha = 0
    }
    
    UIView.animate(
      withDuration: animated ? Constants.pushAnimationDuration * 1.25 : 0,
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
        self.updateCardHandleAccessibility(for: animateTo)
        self.updateResponderChainForNewTopCard()
        self.isPopping = false
        self.toggleCardWrappers(hide: newTop?.view == nil)
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

  fileprivate enum Direction {
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
    
    cardWrapperDesiredTopConstraint.constant = snapTo.y
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
        self.updateFloatingViewsVisibility(for: snapTo.position)
        self.view.layoutIfNeeded()
      }, completion: { _ in
        self.topCard?.mapManager?.edgePadding = self.mapEdgePadding(for: snapTo.position)
        self.topCard?.didMove(to: snapTo.position, animated: true)
        self.updateCardScrolling(allow: snapTo.position == .extended, view: self.topCardView)
        self.previousCardPosition = snapTo.position
        self.updateCardHandleAccessibility(for: snapTo.position)
        completion?()
      })
  }
  
  @objc
  fileprivate func handlePan(_ recogniser: UIPanGestureRecognizer) {
    guard mode == .floating else { return }
    
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
      if #available(iOS 11, *) {
        currentCardY -= (offset + view.safeAreaInsets.bottom)
      } else {
        currentCardY -= (offset + bottomLayoutGuide.length)
      }
    }
    
    // Reposition the card according to the pan as long as the user
    // is dragging in the range of extended and collapsed
    let newY = currentCardY + translation.y
    if (newY >= extendedMinY) && (newY <= collapsedMinY) {
      recogniser.setTranslation(.zero, in: cardWrapperContent)
      cardWrapperDesiredTopConstraint.constant = newY
      
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
    guard mode == .floating, cardPosition == .extended, topCard?.mapManager != nil else { return }
    
    switchTo(.peaking, direction: .down, animated: true)
  }
  
  @objc
  fileprivate func handleInnerPan(_ recogniser: UIPanGestureRecognizer) {
    guard
      mode == .floating,
      let scrollView = recogniser.view as? UIScrollView,
      scrollView == topCardView?.contentScrollView
      else { return }
    
    let negativity = scrollView.contentOffset.y
    
    switch (negativity, recogniser.state) {
    case (0 ..< CGFloat.infinity, _):
      // Reset the transformation whenever we get back to positive offset
      scrollView.transform = .identity
      scrollView.scrollIndicatorInsets = .zero
      
    case (_, .ended), (_, .cancelled):
      // When we finish up, we bring the scroll view back to the state how
      // it's appearing: scrolled to the top with zero inset
      scrollView.transform = .identity
      scrollView.scrollIndicatorInsets = .zero
      scrollView.contentOffset = .zero
      
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
      cardWrapperDesiredTopConstraint.constant = extendedMinY - negativity
      scrollView.transform = CGAffineTransform(translationX: 0, y: negativity)
      if #available(iOS 11.1, *) {
        scrollView.verticalScrollIndicatorInsets.top = negativity * -1
      } else {
        scrollView.scrollIndicatorInsets.top = negativity * -1
      }
      
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
      return
    }
    
    let animateTo = cardLocation(forDesired: position, direction: direction)
    
    cardWrapperDesiredTopConstraint.constant = animateTo.y
    view.setNeedsUpdateConstraints()
    
    UIView.animate(
      withDuration: animated ? Constants.tapAnimationDuration : 0,
      delay: 0,
      options: [.curveEaseOut],
      animations: {
        self.updateMapShadow(for: animateTo.position)
        self.topCardView?.adjustContentAlpha(to: animateTo.position == .collapsed ? 0 : 1)
        self.updateFloatingViewsVisibility(for: animateTo.position)
        self.view.layoutIfNeeded()
    },
      completion: { _ in
        self.topCard?.mapManager?.edgePadding = self.mapEdgePadding(for: animateTo.position)
        self.topCard?.didMove(to: animateTo.position, animated: animated)
        self.updateCardScrolling(allow: animateTo.position == .extended, view: self.topCardView)
        self.previousCardPosition = animateTo.position
        self.updateCardHandleAccessibility(for: animateTo.position)
        handler?()
    })
  }
  
  private func updatePannerInteractivity(for cardElement:
      (card: TGCard, lastPosition: TGCardPosition, view: TGCardView?)? = nil) {
    guard panningAllowed, mode == .floating else { return }
    let card = cardElement?.card ?? topCard
    let isForceExtended = card?.mapManager == nil
    panner.isEnabled = !isForceExtended
  }
  
}

// MARK: - Grab handle

extension TGCardViewController {
  
  private func updateGrabHandleVisibility(for cardElement:
      (card: TGCard, lastPosition: TGCardPosition, view: TGCardView?)? = nil) {
    let card = cardElement?.card ?? topCard
    let view = cardElement?.view ?? topCardView
    let isForceExtended = card?.mapManager == nil || mode == .sidebar
    view?.grabHandles.forEach { $0.isHidden = isForceExtended }
  }
}

// MARK: - Floating views

extension TGCardViewController {
  
  public func toggleMapOverlays(show: Bool, animated: Bool = true) {
    // Map buttons
    if show {
      updateFloatingViewsVisibility(for: cardPosition, animated: animated)
    } else {
      fadeMapFloatingViews(true, animated: animated)
    }
    
    // Card
    UIView.animate(withDuration: animated ? 0.25 : 0) {
      self.topCardView?.alpha = show ? 1 : 0
    }
  }
  
  private func deviceIsiPhoneX() -> Bool {
    if #available(iOS 11, *) {
      return view.safeAreaInsets.bottom > 0
    } else {
      return false
    }
  }
  
  private func fadeMapFloatingViews(_ fade: Bool, animated: Bool) {
    UIView.animate(withDuration: animated ? 0.25: 0) {
      self.topFloatingViewWrapper.alpha = fade ? 0 : 1
      self.bottomFloatingViewWrapper.alpha = fade ? 0 : 1
    }
  }
  
  private func updateFloatingViewsVisibility(for position: TGCardPosition? = nil, animated: Bool = false) {
    if cardIsNextToMap(in: traitCollection) {
      // When card is on the side of the map, always show the floating views.
      fadeMapFloatingViews(false, animated: animated)
    } else {
      fadeMapFloatingViews(position ?? cardPosition == .extended, animated: animated)
    }
  }
  
  private func updateFloatingViewsContent() {
    var topViews: [UIView] = []
    var bottomViews: [UIView] = []
    
    switch locationButtonPosition {
    case .top: topViews = defaultButtons
    case .bottom: bottomViews = defaultButtons
    }
    
    // Because we want to relocate buttons in the top toolbar
    // to the bottom toolbar when header is present, so it is
    // important that we set up bottom toolbar first!
    if let newBottoms = topCard?.bottomMapToolBarItems {
      bottomViews.append(contentsOf: newBottoms)
    }
    
    if !bottomViews.isEmpty {
      populateFloatingView(bottomFloatingView, with: bottomViews)
    } else {
      cleanUpFloatingView(bottomFloatingView)
    }
    
    // Now we can proceed with setting up toolbar at the top.
    if let newTops = topCard?.topMapToolBarItems {
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
  }
  
  private func updateFloatingViewsConstraints() {
    if cardIsNextToMap(in: traitCollection) {
      bottomFloatingViewBottomConstraint.constant = deviceIsiPhoneX() ? 0 : 8
      if deviceIsiPhoneX() {
        if #available(iOS 11, *) {
          topFloatingViewTopConstraint.constant = view.safeAreaInsets.bottom
        }
        NSLayoutConstraint.deactivate([
          topFloatingViewTrailingToSafeAreaConstraint,
          bottomFloatingViewTrailingToSafeAreaConstraint
        ])
        NSLayoutConstraint.activate([
          topFloatingViewTrailingToSuperConstraint,
          bottomFloatingViewTrailingToSuperConstraint
        ])
      } else {
        topFloatingViewTopConstraint.constant = 8
        NSLayoutConstraint.deactivate([
          topFloatingViewTrailingToSuperConstraint,
          bottomFloatingViewTrailingToSuperConstraint
        ])
        NSLayoutConstraint.activate([
          topFloatingViewTrailingToSafeAreaConstraint,
          bottomFloatingViewTrailingToSafeAreaConstraint
        ])
      }
    } else {
      
      topFloatingViewTopConstraint.constant = 8
      NSLayoutConstraint.deactivate([
        topFloatingViewTrailingToSuperConstraint,
        bottomFloatingViewTrailingToSuperConstraint
      ])
      NSLayoutConstraint.activate([
        topFloatingViewTrailingToSafeAreaConstraint,
        bottomFloatingViewTrailingToSafeAreaConstraint
      ])
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
        if #available(iOS 13.0, *) {
          separator.backgroundColor = .separator
        } else {
          separator.backgroundColor = UIColor(white: 1.0, alpha: 0.85)
        }
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

  fileprivate var isShowingHeader: Bool {
    return headerViewTopConstraint.constant > -1
  }
  
  private func updateHeaderStyle() {
    func applyCornerStyle(to view: UIView) {
      let radius: CGFloat = 16
      let roundAllCorners = cardIsNextToMap(in: traitCollection)
      
      if #available(iOS 11.0, *) {
        view.layer.maskedCorners = roundAllCorners
          ? [.layerMinXMaxYCorner, .layerMinXMinYCorner,
             .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
          : [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        view.layer.cornerRadius = radius
      
      } else {
        let cornerRadius: CGFloat = roundAllCorners ? radius : 0
        view.layer.cornerRadius = cornerRadius
      }
    }
    
    headerView.backgroundColor = topCard?.style.backgroundColor ?? .white
    applyCornerStyle(to: headerView)
    headerView.subviews.compactMap { $0 as? TGHeaderView }.forEach(applyCornerStyle(to:))
    updateStatusBar(headerIsVisible: isShowingHeader)

    // same shadow as for card wrapper
    headerView.layer.shadowColor = UIColor.black.cgColor
    headerView.layer.shadowOffset = .zero
    headerView.layer.shadowRadius = 12
    headerView.layer.shadowOpacity = 0.5

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
    setNeedsStatusBarAppearanceUpdate()
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
    
    return false
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
    guard panningAllowed, card === topCard, let view = topCardView else { return }
    
    old?.panGestureRecognizer.removeTarget(self, action: nil)
    view.contentScrollView?.panGestureRecognizer.addTarget(self, action: #selector(handleInnerPan(_:)))
  }
  
}


// MARK: - VoiceOver

extension TGCardViewController {
  
  override open func accessibilityPerformEscape() -> Bool {
    return popMaybe()
  }
  
  private func monitorVoiceOverStatus() {
    if #available(iOS 11.0, *) {
      NotificationCenter.default.addObserver(self, selector: #selector(updateForVoiceOverStatusChange),
                                             name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
    }
  }
  
  @objc
  private func updateForVoiceOverStatusChange() {
    updateCardScrolling(allow: cardPosition == .extended, view: topCardView)
  }
  
  private func buildCardHandleAccessibilityActions() -> [UIAccessibilityCustomAction] {
    return [
      UIAccessibilityCustomAction(
        name: NSLocalizedString("Collapse", bundle: .cardVC, comment: "Accessibility action to collapse card"),
        target: self, selector: #selector(collapse)
      ),
      UIAccessibilityCustomAction(
        name: NSLocalizedString("Expand", bundle: .cardVC, comment: "Accessibility action to expand card"),
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

  private func updateCardHandleAccessibility(for position: TGCardPosition? = nil) {
    topCardView?.grabHandles.forEach { updateCardHandleAccessibility(handle: $0, position: position) }
  }
    
  private func updateCardHandleAccessibility(handle: TGGrabHandleView, position: TGCardPosition?) {
    handle.isAccessibilityElement = true
    handle.accessibilityCustomActions = buildCardHandleAccessibilityActions()
    
    switch position ?? cardPosition {
    case .collapsed:
      handle.accessibilityLabel = NSLocalizedString(
        "Card controller minimised", bundle: .cardVC,
        comment: "Card handle accessibility description for collapsed state"
      )
      
    case .extended:
      handle.accessibilityLabel = NSLocalizedString(
        "Card controller full screen", bundle: .cardVC,
        comment: "Card handle accessibility description for collapsed state"
      )

    case .peaking:
      handle.accessibilityLabel = NSLocalizedString(
        "Card controller half screen", bundle: .cardVC,
        comment: "Card handle accessibility description for collapsed state"
      )
    }
    
    handle.accessibilityHint = NSLocalizedString(
      "Adjust the size of the card overlaying the map.", bundle: .cardVC,
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
        input: UIKeyCommand.inputUpArrow, modifierFlags: .control, action: #selector(expand),
        maybeDiscoverabilityTitle: NSLocalizedString(
          "Expand card", bundle: .cardVC,
          comment: "Discovery hint for keyboard shortcuts"
        )
      ),
      UIKeyCommand(
        input: UIKeyCommand.inputDownArrow, modifierFlags: .control, action: #selector(collapse),
        maybeDiscoverabilityTitle: NSLocalizedString(
          "Collapse card", bundle: .cardVC,
          comment: "Discovery hint for keyboard shortcuts"
        )
      ),
    ]
    
    if presentedViewController != nil {
      commands.append(
        UIKeyCommand(
          input: "w", modifierFlags: .command, action: #selector(dismissPresentee),
          maybeDiscoverabilityTitle: NSLocalizedString(
            "Dismiss", bundle: .cardVC,
            comment: "Discovery hint for keyboard shortcuts"
          )
      ))
      
      #if targetEnvironment(macCatalyst)
      commands.append(
        UIKeyCommand(
          input: "d", modifierFlags: .command, action: #selector(dismissPresentee)
      ))
      #else
      commands.append(
        UIKeyCommand(
          input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(dismissPresentee)
      ))
      #endif


    } else if topCard != nil, cards.count > 1 || delegate != nil {
      commands.append(
        UIKeyCommand(
          input: "[", modifierFlags: .command, action: #selector(pop),
          maybeDiscoverabilityTitle: NSLocalizedString(
            "Back to previous card", bundle: .cardVC,
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

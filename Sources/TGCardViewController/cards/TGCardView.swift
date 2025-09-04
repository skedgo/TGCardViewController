//
//  TGCardView.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import SwiftUI
import UIKit

public protocol TGInteractiveCardTitle: UIView {
  
  /// This method returns frames that cover the interactive areas of a card title in a
  /// `TGCardView`. If the card title does not contain interactive components, this
  /// method should return an empty array.
  ///
  /// - Parameter cardView: The parent view that contains the card title. This
  /// is typically a subclass of `TGCardView`
  func interactiveFrames(relativeTo cardView: TGCardView) -> [CGRect]
  
}

public protocol TGPreferrableView {
  var preferredView: UIView? { get }
}

/// The view for the card itself.
///
/// Cannot be subclassed, by usually used to programatically update the
/// title/subtitle of the card or to get access to the card's table view or
/// collection view - by checking if an instance of this class is a
/// `TGScrollCardView` instance.
public class TGCardView: TGCornerView, TGPreferrableView {
  
  /// Each card view needs a grab handle, which the controller
  /// might hide and show.
  /// - Note: If you apply any logic to this, don't use this but `grabHandles`
  @IBOutlet weak var grabHandle: TGGrabHandleView?
  
  @IBOutlet weak var titleViewPlaceholder: UIView?
  
  /// This is the line separating the header and content parts of a
  /// card view.
  @IBOutlet weak var contentSeparator: UIView?
  
  /// Each card view needs a scroll view where the main content of the
  /// card goes. The card controller need access to it, in order to
  /// handling dragging the card up and down.
  @IBOutlet weak var contentScrollView: UIScrollView? {
    didSet {
      contentScrollViewObservation = contentScrollView?
        .observe(\UIScrollView.contentOffset) { [weak self] scrollView, _ in
          guard scrollView.isScrollEnabled else { return }
          let scrollOffset = scrollView.contentOffset.y
          
          // What is this you ask? This deals with dragging down the card by
          // the content of the scroll view. This is achieved by setting a
          // transform in `TGCardViewController`. Technially, you'd want to
          // subtract the transform.ty from the scroll offset, however the
          // transform lags behind the offset by a few frames. So we simplify
          // this to just treat it as 0 offset if there's a transform as you
          // drag down, which pins the scroll view effectively to a "visual"
          // offset of 0.
          let actualOffset = scrollView.transform.ty < 0 ? 0 : scrollOffset
          self?.showSeparator(actualOffset > 0, offset: actualOffset)
      }
    }
  }
  
  weak var titleView: UIView?
  
  weak var customDismissButton: UIButton?
  
  private var titleHost: UIHostingController<AnyView>?
  
  private var contentScrollViewObservation: NSKeyValueObservation?
  
  var grabHandles: [TGGrabHandleView] {
    [grabHandle].compactMap { $0 }
  }
  
  /// The height of the header part of the view, i.e., everything
  /// up to where `contentScrollView` starts.
  ///
  /// - Warning: Might not be accurate if the view hasn't been layed out.
  var headerHeight: CGFloat {
    guard let separator = contentSeparator else { return 0 }
    return separator.frame.maxY
  }
  
  /// The preferred view to select using VoiceOver or similar technologies
  /// when this card appears.
  public var preferredView: UIView? {
    (titleView as? TGPreferrableView)?.preferredView ?? titleView ?? self
  }
  
  override public func awakeFromNib() {
    super.awakeFromNib()
    
    contentSeparator?.isHidden = true
    contentSeparator?.backgroundColor = .opaqueSeparator
  }
  
  // MARK: - Content Configuration
  
  /// Updates the title and subtitle, when the `.default` title was used.
  ///
  /// Does nothing when something other than the `.default` title configuration
  /// was used, or when currently presented in a pager.
  ///
  /// - Parameters:
  ///   - title: New title
  ///   - subtitle: New subtitle (optional)
  public func updateDefaultTitle(title: String, subtitle: String?) {
    guard let defaultView = titleView as? TGCardDefaultTitleView else { return }    
    defaultView.update(title: title, subtitle: subtitle, style: owningCard?.style ?? .default)
  }
  
  func updateDismissButton(show: Bool, isSpringLoaded: Bool) {
    dismissButton?.isHidden = !show
    dismissButton?.isSpringLoaded = isSpringLoaded
  }
  
  weak var owningCard: TGCard?
  
  public override var canBecomeFirstResponder: Bool { true }
  
  public override var next: UIResponder? { owningCard }
  
  func configure(with card: TGCard) {
    self.owningCard = card
    
    if let placeholder = titleViewPlaceholder {
      let titleView: UIView
      switch card.title {
      case .default(let title, let subtitle, let accessoryView):
        let defaultTitleView = TGCardDefaultTitleView.newInstance()
        defaultTitleView.prepare(title: title, subtitle: subtitle, style: card.style)
        defaultTitleView.accessoryView = accessoryView
        titleView = defaultTitleView
        
      case .custom(let view, let button):
        titleView = view
        customDismissButton = button
        
      case .customExtended(let view):
        let titleHost = UIHostingController(rootView: AnyView(view))
        self.titleHost = titleHost
        titleHost.view.backgroundColor = .clear
        titleView = titleHost.view

      case .none:
        let emptyView = UIView()
        emptyView.heightAnchor.constraint(equalToConstant: 0).isActive = true
        titleView = emptyView
      }
      
      placeholder.addSubview(titleView)
      titleView.snap(to: placeholder)
      
      self.titleView = titleView
    }
    
    // Apply custom styling
    applyStyling(card.style)
  }
  
  // MARK: - Title View Configuration
  
  var dismissButton: UIButton? {
    if let dismissButton = customDismissButton {
      return dismissButton
    } else if let defaultTitleView = titleViewPlaceholder?.subviews.first as? TGCardDefaultTitleView {
      return defaultTitleView.dismissButton
    } else {
      return nil
    }
  }
  
  func interactiveTitleContains(_ point: CGPoint) -> Bool {
    guard
      let titlePlaceholder = titleViewPlaceholder,
      let interactiveTitle = titlePlaceholder.subviews.first as? TGInteractiveCardTitle
      else { return false }
    
    let frames = interactiveTitle.interactiveFrames(relativeTo: self)
    return frames.contains { $0.contains(point) }
  }
  
  func headerHeight(for position: TGCardPosition) -> CGFloat {
    if let contentSeparator {
      return contentSeparator.frame.maxY
    }
    
    guard let scrollView = contentScrollView else {
      return 0
    }
    
    switch position {
    case .collapsed:
      var frame: CGRect
      
      if let titlePlaceholder = titleViewPlaceholder,
        let defaultTitleView = titlePlaceholder.subviews.first as? TGCardDefaultTitleView,
        let accessoryPlaceholder = defaultTitleView.accessoryViewContainer,
        let accessory = accessoryPlaceholder.subviews.first {
        // The frame of the accessory view in the coordinate system
        // of card view itself
        frame = accessoryPlaceholder.convert(accessory.frame, to: self)
      } else {
        // The frame of the scroll view in the coordinate system of
        // card view itself. Note, the scroll view may be embedded
        // inside another view, so we check for its superview here.
        frame = scrollView.superview?.convert(scrollView.frame, to: self) ?? scrollView.frame
      }
      
      if let handle = grabHandle {
        // If we have a grab handle, need to account for whether its hidden. If
        // its hideen, its space in the card view is reduced to 0.
        return handle.isHidden ? frame.minY - handle.frame.height : frame.minY
      } else {
        return frame.minY
      }
      
    default:
      return scrollView.superview?.convert(scrollView.frame, to: self).minY ?? scrollView.frame.minY
    }
  }
  
  // MARK: - Managing Appearance
  
  func applyStyling(_ style: TGCardStyle) {
    grabHandles.forEach { $0.handleColor = style.grabHandleColor }
    
    #if targetEnvironment(macCatalyst)
    backgroundColor = .clear
    #else
    backgroundColor = style.backgroundColor
    #endif
  }
  
  // MARK: - Content view configuration
  
  private var forceHideSeparator = false
  
  func setSeparatorVisibility(forceHidden: Bool) {
    forceHideSeparator = forceHidden
    // Trigger separator update with current scroll state
    if let contentScrollView = contentScrollView {
      let actualOffset = contentScrollView.transform.ty < 0 ? 0 : contentScrollView.contentOffset.y
      showSeparator(actualOffset > 0, offset: actualOffset)
    }
  }
  
  func showSeparator(_ show: Bool, offset: CGFloat) {
    if let owningCard, owningCard.shouldToggleSeparator(show: show, offset: offset) {
      contentSeparator?.isHidden = forceHideSeparator ? true : !show
      
    } else if let owningCard, owningCard.title.isExtended, owningCard.autoIgnoreContentInset, let contentScrollView, contentScrollView.isDecelerating, offset < 0 {
      // This handles the case where you fling the content down further than the
      // top. It looks wierd if this would then scroll or bounce into negative
      // space, so we just stop apruptly at 0.
      // We consider `.isDecelerating` to let you do this while actively
      // dragging, to not stop that gesture, as that would brea, dragging the
      // card down by the scroll view, when you start with a scroll.
      contentScrollView.contentOffset.y = 0
    }
  }
  
  func allowContentScrolling(_ allowScrolling: Bool) {
    contentScrollView?.isScrollEnabled = allowScrolling
    
    // Disabling this seems to scroll weirdly enough; so if we want to
    // ignore the content inset; let's just pin it to th top.
    if !allowScrolling, owningCard?.autoIgnoreContentInset == true {
      contentScrollView?.contentOffset.y = 0
    }
  }
  
  func adjustContentAlpha(to value: CGFloat) {
    owningCard?.willAdjustContentAlpha(value)
    
    contentScrollView?.alpha = value
  }
  
}

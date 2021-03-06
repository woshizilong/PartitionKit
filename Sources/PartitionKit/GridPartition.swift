//
//  GridPartition.swift
//  
//
//  Created by Kieran Brown on 10/26/19.
//

import Foundation
import SwiftUI


/// # Grid Partition
/// Creates a flexible container view with four separate partitions and a draggable `Handle` in the center.
/// Don't be afraid of the syntax, The View takes at minimum four closures each containing some type that conforms to `View`.
/// The reason that 5 separate generic arguments are used is so that the user can avoid wrapping everything in an `AnyView`.
///
/// - note
/// the syntax looks something like this, So if closures are still kind of new to you just think that you are sending a letter(`View`) to somebody  and it needs an Envelope(`{}`) to get there.
/// ```
/// GridPart(topLeft: {
///     Circle()
/// }, topRight: {
///    Rectangle()
/// }, bottomLeft: {
///     RoundedRectangle(cornerRadius: 25)
/// }, bottomRight {
///     Capsule()
/// }), {
///     CrossHair()
/// }
///
///```
///
///
///
/// Optionally the user may specify a specific view to be used as the `Handle` otherwise the View `CrossHair` will be used as default
@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
public struct GridPart<TopLeft, TopRight, BottomLeft, BottomRight, Handle> where TopLeft: View , TopRight: View, BottomLeft: View, BottomRight:View, Handle: View {
    
    public var topLeft: TopLeft
    public var topRight: TopRight
    public var bottomLeft: BottomLeft
    public var bottomRight: BottomRight
    public var handle: Handle
    
    /// Amount of time it takes before a gesture is recognized as a longPress, the precursor to the drag.
    var minimumLongPressDuration = 0.05
    /// Size of the `Handle`
    var handleSize: CGSize = CGSize(width: 40, height: 40)
    public var pctSplit: CGSize = CGSize(width: 0.5, height: 0.5)
    var paddingFactor: CGFloat = 0.9
    
    // dragState and viewState are also taken directly froms Apples "Composing SwiftUI Gestures"
    @GestureState var dragState = DragState.inactive
    @State var viewState = CGSize.zero
    
    // A bit of a convienence so I dont have to write this again and again.
    var currentOffset: CGSize {
        CGSize(width: viewState.width+dragState.translation.width,
               height: viewState.height+dragState.translation.height)
    }
    
    
    /// Creates the `Handle` and adds the drag gesture to it.
    func generateHandle() -> some View {
        
        // This gesture sequence is also directly from apples "Composing SwiftUI Gestures"
        let longPressDrag = LongPressGesture(minimumDuration: minimumLongPressDuration)
            .sequenced(before: DragGesture())
            .updating($dragState) { value, state, transaction in
                switch value {
                // Long press begins.
                case .first(true):
                    state = .pressing
                // Long press confirmed, dragging may begin.
                case .second(true, let drag):
                    state = .dragging(translation: drag?.translation ?? .zero)
                // Dragging ended or the long press cancelled.
                default:
                    state = .inactive
                }
        }
        .onEnded { value in
            guard case .second(true, let drag?) = value else { return }
            self.viewState.height += drag.translation.height
            self.viewState.width += drag.translation.width
            
        }
        
        // MARK: Customize Handle Here
        // Add the gestures and visuals to the handle
        return handle.overlay(dragState.isDragging ? Circle().stroke(Color.white, lineWidth: 2) : nil)
            .foregroundColor(.white)
            .frame(width: handleSize.width, height: handleSize.height, alignment: .center)
            .offset(currentOffset)
            .animation(.linear)
            .gesture(longPressDrag)
    }
    
    
    // MARK: Money Shot
    public var body: some View {
        GeometryReader { (proxy: GeometryProxy) in
            VStack {
                // Top
                HStack {
                    self.topLeft
                        .frame(width: self.paddingFactor*(self.pctSplit.width*proxy.frame(in: .local).width) + self.currentOffset.width)
                    Divider()
                    self.topRight
                        .frame(width: self.paddingFactor*((1-self.pctSplit.width)*proxy.frame(in: .local).width) - self.currentOffset.width)
                }.frame(height: self.paddingFactor*(self.pctSplit.height*proxy.frame(in: .local).height) + self.currentOffset.height)
                Divider()
                // Bottom
                HStack {
                    self.bottomLeft
                        .frame(width: self.paddingFactor*(self.pctSplit.width*proxy.frame(in: .local).width) + self.currentOffset.width)
                    Divider()
                    self.bottomRight
                        .frame(width: self.paddingFactor*((1-self.pctSplit.width)*proxy.frame(in: .local).width) - self.currentOffset.width)
                }.frame(height: self.paddingFactor*((1-self.pctSplit.height)*proxy.frame(in: .local).height) - self.currentOffset.height)
            }.overlay(self.generateHandle(), alignment: .center)
        }
    }
}


@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
extension GridPart: View where TopLeft:View, TopRight: View, BottomLeft: View, BottomRight: View, Handle: View {
    
    /// # GridPartition With Custom Handle
    /// - parameters:
    ///   - topLeft Any type of View within a closure.
    ///   - topRight Any type of View within a closure.
    ///   - bottomLeft Any type of View within a closure.
    ///   - bottomLeft Any type of View within a closure.
    ///   - handle Any type of View within a closure, This is the view that the user will drag to resize all the others.
    @inlinable public init(@ViewBuilder topLeft: () -> TopLeft, @ViewBuilder topRight: () -> TopRight,@ViewBuilder  bottomLeft: () -> BottomLeft, @ViewBuilder bottomRight: () -> BottomRight, @ViewBuilder handle: () -> Handle ) {
        self.topLeft = topLeft()
        self.topRight = topRight()
        self.bottomLeft = bottomLeft()
        self.bottomRight = bottomRight()
        self.handle = handle()
    }
    
    
    /// # GridPartition With Custom Handle
    /// - parameters:
    ///   - pctSplit The inital percentage size each partition should take up
    ///   - topLeft Any type of View within a closure.
    ///   - topRight Any type of View within a closure.
    ///   - bottomLeft Any type of View within a closure.
    ///   - bottomLeft Any type of View within a closure.
    ///   - handle Any type of View within a closure, This is the view that the user will drag to resize all the others.
    @inlinable public init(pctSplit: CGSize, @ViewBuilder topLeft: () -> TopLeft, @ViewBuilder topRight: () -> TopRight,@ViewBuilder  bottomLeft: () -> BottomLeft, @ViewBuilder bottomRight: () -> BottomRight, @ViewBuilder handle: () -> Handle ) {
        self.pctSplit = pctSplit
        self.topLeft = topLeft()
        self.topRight = topRight()
        self.bottomLeft = bottomLeft()
        self.bottomRight = bottomRight()
        self.handle = handle()
    }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0 , tvOS 13.0, *)
extension GridPart where Handle == CrossHair, TopLeft:View, TopRight: View, BottomLeft: View, BottomRight: View {
    
    
    /// # GridPartition With Crosshair Handle
    /// A slight convienence because you do not have to specify a handle, the default  `CrossHair` is used instead.
    ///
    /// - parameters:
    ///   - topLeft Any type of View within a closure.
    ///   - topRight Any type of View within a closure.
    ///   - bottomLeft Any type of View within a closure.
    ///   - bottomLeft Any type of View within a closure.
    ///
    /// Uses the default `CrossHair` as the `Handle`.
    @inlinable public init(@ViewBuilder topLeft: () -> TopLeft, @ViewBuilder topRight: () -> TopRight,@ViewBuilder  bottomLeft: () -> BottomLeft, @ViewBuilder bottomRight: () -> BottomRight) {
        self.topLeft = topLeft()
        self.topRight = topRight()
        self.bottomLeft = bottomLeft()
        self.bottomRight = bottomRight()
        self.handle = CrossHair()
    }
    
    
    /// # GridPartition With Crosshair Handle
    /// A slight convienence because you do not have to specify a handle, the default  `CrossHair` is used instead.
    ///
    /// - parameters:
    ///   - pctSplit The inital percentage size each partition should take up
    ///   - topLeft Any type of View within a closure.
    ///   - topRight Any type of View within a closure.
    ///   - bottomLeft Any type of View within a closure.
    ///   - bottomLeft Any type of View within a closure.
    ///
    /// Uses the default `CrossHair` as the `Handle`.
    @inlinable public init(pctSplit: CGSize, @ViewBuilder topLeft: () -> TopLeft, @ViewBuilder topRight: () -> TopRight,@ViewBuilder  bottomLeft: () -> BottomLeft, @ViewBuilder bottomRight: () -> BottomRight) {
        self.pctSplit = pctSplit    
        self.topLeft = topLeft()
        self.topRight = topRight()
        self.bottomLeft = bottomLeft()
        self.bottomRight = bottomRight()
        self.handle = CrossHair()
    }
}

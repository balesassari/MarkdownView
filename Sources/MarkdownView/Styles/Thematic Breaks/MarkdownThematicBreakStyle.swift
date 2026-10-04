//
//  MarkdownThematicBreakStyle.swift
//  MarkdownView
//

import SwiftUI

/// A type that applies a custom style to all thematic breaks (`---`) within a MarkdownView.
///
/// Don't directly access view dependencies (e.g. `@Environment`), use a separate view instead.
@preconcurrency
@MainActor
public protocol MarkdownThematicBreakStyle {
    /// A view that represents the current thematic break.
    associatedtype Body: View
    /// Creates the view that represents the current thematic break.
    @preconcurrency
    @MainActor
    @ViewBuilder
    func makeBody(configuration: Configuration) -> Body
    /// The properties of a thematic break.
    typealias Configuration = MarkdownThematicBreakStyleConfiguration
}

/// The properties of a thematic break. A break has no content, so this is empty for now.
public struct MarkdownThematicBreakStyleConfiguration {
    init() { }
}

/// The thematic break style that draws a divider.
public struct DefaultMarkdownThematicBreakStyle: MarkdownThematicBreakStyle {
    public init() { }

    public func makeBody(configuration: Configuration) -> some View {
        Divider()
    }
}

extension MarkdownThematicBreakStyle where Self == DefaultMarkdownThematicBreakStyle {
    /// The thematic break style that draws a divider.
    static public var `default`: DefaultMarkdownThematicBreakStyle { .init() }
}

// MARK: - Environment Value

struct MarkdownThematicBreakStyleKey: @preconcurrency EnvironmentKey {
    @MainActor static var defaultValue: any MarkdownThematicBreakStyle = DefaultMarkdownThematicBreakStyle()
}

extension EnvironmentValues {
    var markdownThematicBreakStyle: any MarkdownThematicBreakStyle {
        get { self[MarkdownThematicBreakStyleKey.self] }
        set { self[MarkdownThematicBreakStyleKey.self] = newValue }
    }
}

// MARK: - Styled View

struct MarkdownStyledThematicBreak: View {
    @Environment(\.markdownThematicBreakStyle) private var thematicBreakStyle

    var body: some View {
        thematicBreakStyle
            .makeBody(configuration: MarkdownThematicBreakStyleConfiguration())
            .erasedToAnyView()
    }
}

// MARK: - Modifier

extension View {
    /// Sets the style for thematic breaks within this view.
    ///
    /// - Parameter style: The style to apply to every thematic break.
    nonisolated public func markdownThematicBreakStyle(_ style: some MarkdownThematicBreakStyle) -> some View {
        environment(\.markdownThematicBreakStyle, style)
    }
}

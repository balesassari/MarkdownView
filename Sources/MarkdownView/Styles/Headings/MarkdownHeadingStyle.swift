//
//  MarkdownHeadingStyle.swift
//  MarkdownView
//

import SwiftUI

/// A type that applies a custom style to all headings within a MarkdownView.
///
/// The configuration's content already carries the font and foreground style for its level,
/// so a style only adds what goes around or behind the text, such as tracking, a text case
/// or a text renderer.
///
/// Don't directly access view dependencies (e.g. `@Environment`), use a separate view instead.
@preconcurrency
@MainActor
public protocol MarkdownHeadingStyle {
    /// A view that represents the current heading.
    associatedtype Body: View
    /// Creates the view that represents the current heading.
    @preconcurrency
    @MainActor
    @ViewBuilder
    func makeBody(configuration: Configuration) -> Body
    /// The properties of a heading.
    typealias Configuration = MarkdownHeadingStyleConfiguration
}

/// The properties of a heading.
public struct MarkdownHeadingStyleConfiguration {
    /// The heading level, from 1 to 6.
    public var level: Int
    /// The rendered heading text, with the font and foreground style for its level.
    public var content: Content

    /// A type-erased content of a heading.
    public struct Content: View {
        private var content: AnyView

        init(_ content: some View) {
            self.content = AnyView(content)
        }

        @_documentation(visibility: internal)
        public var body: some View {
            content
        }
    }
}

@available(*, unavailable)
extension MarkdownHeadingStyleConfiguration: Sendable {

}

/// The heading style that draws the heading text as it is.
public struct DefaultMarkdownHeadingStyle: MarkdownHeadingStyle {
    public init() { }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.content
    }
}

extension MarkdownHeadingStyle where Self == DefaultMarkdownHeadingStyle {
    /// The heading style that draws the heading text as it is.
    static public var `default`: DefaultMarkdownHeadingStyle { .init() }
}

// MARK: - Environment Value

struct MarkdownHeadingStyleKey: @preconcurrency EnvironmentKey {
    @MainActor static var defaultValue: any MarkdownHeadingStyle = DefaultMarkdownHeadingStyle()
}

extension EnvironmentValues {
    var markdownHeadingStyle: any MarkdownHeadingStyle {
        get { self[MarkdownHeadingStyleKey.self] }
        set { self[MarkdownHeadingStyleKey.self] = newValue }
    }
}

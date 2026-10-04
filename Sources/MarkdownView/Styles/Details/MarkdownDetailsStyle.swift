//
//  MarkdownDetailsStyle.swift
//  MarkdownView
//

import SwiftUI

/// A type that applies a custom style to all collapsible sections (`<details>` with a
/// `<summary>`) within a MarkdownView.
///
/// Don't directly access view dependencies (e.g. `@Environment`), use a separate view instead.
@preconcurrency
@MainActor
public protocol MarkdownDetailsStyle {
    /// A view that represents the current collapsible section.
    associatedtype Body: View
    /// Creates the view that represents the current collapsible section.
    @preconcurrency
    @MainActor
    @ViewBuilder
    func makeBody(configuration: Configuration) -> Body
    /// The properties of a collapsible section.
    typealias Configuration = MarkdownDetailsStyleConfiguration
}

/// The properties of a collapsible section.
public struct MarkdownDetailsStyleConfiguration {
    /// The summary line: the text of `<summary>`, or "Details" when there is none, as on GitHub.
    public var summary: Summary
    /// The blocks inside the section.
    public var content: Content
    /// Whether the section is open. It starts open for `<details open>`.
    @Binding public var isExpanded: Bool

    init(summary: Summary, content: Content, isExpanded: Binding<Bool>) {
        self.summary = summary
        self.content = content
        self._isExpanded = isExpanded
    }

    /// A type-erased summary line.
    public struct Summary: View {
        private var content: AnyView

        init(@ViewBuilder _ content: () -> some View) {
            self.content = AnyView(content())
        }

        @_documentation(visibility: internal)
        public var body: some View {
            content
        }
    }

    /// The type-erased blocks of a section.
    public struct Content: View {
        private var content: AnyView

        init(@ViewBuilder _ content: () -> some View) {
            self.content = AnyView(content())
        }

        @_documentation(visibility: internal)
        public var body: some View {
            content
        }
    }
}

@available(*, unavailable)
extension MarkdownDetailsStyleConfiguration: Sendable {

}

/// The collapsible section style that shows a chevron before the summary and the content
/// below it when open.
public struct DefaultMarkdownDetailsStyle: MarkdownDetailsStyle {
    public init() { }

    public func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    configuration.isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Image(systemName: "chevron.right")
                        .imageScale(.small)
                        .rotationEffect(.degrees(configuration.isExpanded ? 90 : 0))
                    configuration.summary
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if configuration.isExpanded {
                configuration.content
            }
        }
    }
}

extension MarkdownDetailsStyle where Self == DefaultMarkdownDetailsStyle {
    /// The collapsible section style that shows a chevron before the summary.
    static public var `default`: DefaultMarkdownDetailsStyle { .init() }
}

// MARK: - Environment Value

struct MarkdownDetailsStyleKey: @preconcurrency EnvironmentKey {
    @MainActor static var defaultValue: any MarkdownDetailsStyle = DefaultMarkdownDetailsStyle()
}

extension EnvironmentValues {
    var markdownDetailsStyle: any MarkdownDetailsStyle {
        get { self[MarkdownDetailsStyleKey.self] }
        set { self[MarkdownDetailsStyleKey.self] = newValue }
    }
}

// MARK: - Styled View

struct MarkdownDetails: View {
    var summary: MarkdownNodeView
    var content: MarkdownNodeView
    @State private var isExpanded: Bool
    @Environment(\.markdownDetailsStyle) private var detailsStyle

    init(summary: MarkdownNodeView, content: MarkdownNodeView, isInitiallyExpanded: Bool) {
        self.summary = summary
        self.content = content
        self._isExpanded = State(initialValue: isInitiallyExpanded)
    }

    var body: some View {
        detailsStyle
            .makeBody(configuration: MarkdownDetailsStyleConfiguration(
                summary: .init { summary },
                content: .init { content },
                isExpanded: $isExpanded
            ))
            .erasedToAnyView()
    }
}

// MARK: - Modifier

extension View {
    /// Sets the style for collapsible sections (`<details>`) within this view.
    ///
    /// - Parameter style: The style to apply to every collapsible section.
    nonisolated public func markdownDetailsStyle(_ style: some MarkdownDetailsStyle) -> some View {
        environment(\.markdownDetailsStyle, style)
    }
}

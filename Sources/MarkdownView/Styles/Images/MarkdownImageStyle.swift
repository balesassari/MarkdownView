//
//  MarkdownImageStyle.swift
//  MarkdownView
//

import SwiftUI

/// A type that applies a custom style to loaded network and relative-path images within a MarkdownView.
///
/// The style only applies once the image has loaded; loading and failure placeholders stay as they are.
///
/// Don't directly access view dependencies (e.g. `@Environment`), use a separate view instead.
@preconcurrency
@MainActor
public protocol MarkdownImageStyle {
    /// A view that represents the current image.
    associatedtype Body: View
    /// Creates the view that represents the current image.
    @preconcurrency
    @MainActor
    @ViewBuilder
    func makeBody(configuration: Configuration) -> Body
    /// The properties of an image.
    typealias Configuration = MarkdownImageStyleConfiguration
}

/// The properties of a loaded image.
public struct MarkdownImageStyleConfiguration {
    /// The loaded image, sized the way MarkdownView sizes it.
    public var content: Content
    /// The image's alternative text, if it has any.
    public var alternativeText: String?

    /// A type-erased loaded image.
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
extension MarkdownImageStyleConfiguration: Sendable {

}

/// The image style that shows the image with its alternative text underneath.
public struct DefaultMarkdownImageStyle: MarkdownImageStyle {
    public init() { }

    public func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.content
            if let alternativeText = configuration.alternativeText {
                Text(alternativeText)
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
        }
    }
}

extension MarkdownImageStyle where Self == DefaultMarkdownImageStyle {
    /// The image style that shows the image with its alternative text underneath.
    static public var `default`: DefaultMarkdownImageStyle { .init() }
}

// MARK: - Environment Value

struct MarkdownImageStyleKey: @preconcurrency EnvironmentKey {
    @MainActor static var defaultValue: any MarkdownImageStyle = DefaultMarkdownImageStyle()
}

extension EnvironmentValues {
    var markdownImageStyle: any MarkdownImageStyle {
        get { self[MarkdownImageStyleKey.self] }
        set { self[MarkdownImageStyleKey.self] = newValue }
    }
}

// MARK: - Modifier

extension View {
    /// Sets the style for loaded images within this view.
    ///
    /// - Parameter style: The style to apply to every loaded network or relative-path image.
    nonisolated public func markdownImageStyle(_ style: some MarkdownImageStyle) -> some View {
        environment(\.markdownImageStyle, style)
    }
}

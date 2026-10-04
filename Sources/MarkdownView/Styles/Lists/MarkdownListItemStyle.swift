//
//  MarkdownListItemStyle.swift
//  MarkdownView
//

import SwiftUI

/// A type that applies a custom style to all list items within a MarkdownView.
///
/// Use it to draw your own bullets, numbers or task checkboxes, or to style finished tasks.
///
/// Don't directly access view dependencies (e.g. `@Environment`), use a separate view instead.
@preconcurrency
@MainActor
public protocol MarkdownListItemStyle {
    /// A view that represents the current list item.
    associatedtype Body: View
    /// Creates the view that represents the current list item.
    @preconcurrency
    @MainActor
    @ViewBuilder
    func makeBody(configuration: Configuration) -> Body
    /// The properties of a list item.
    typealias Configuration = MarkdownListItemStyleConfiguration
}

/// The properties of a list item.
public struct MarkdownListItemStyleConfiguration {
    /// The state of a task list item's checkbox.
    public enum Checkbox: Hashable, Sendable {
        case checked
        case unchecked
    }

    /// Whether the item belongs to an ordered list.
    public var isOrdered: Bool
    /// The item's zero-based position in its list.
    public var index: Int
    /// The number an ordered list shows for this item, honouring the list's start number.
    public var ordinal: Int
    /// How deeply the item's list is nested; 0 for a top-level list.
    public var depth: Int
    /// The checkbox of a task list item, or `nil` for a plain item.
    public var checkbox: Checkbox?
    /// The marker MarkdownView would draw: a bullet, a number or a checkbox.
    public var marker: Marker
    /// The rendered content of the item, including any nested lists.
    public var content: Content

    /// A type-erased marker of a list item.
    public struct Marker: View {
        private var marker: AnyView

        init(_ marker: some View) {
            self.marker = AnyView(marker)
        }

        @_documentation(visibility: internal)
        public var body: some View {
            marker
        }
    }

    /// A type-erased content of a list item.
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
extension MarkdownListItemStyleConfiguration: Sendable {

}

/// The list item style that places the marker before the content.
public struct DefaultMarkdownListItemStyle: MarkdownListItemStyle {
    public init() { }

    public func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline) {
            configuration.marker
            configuration.content
        }
    }
}

extension MarkdownListItemStyle where Self == DefaultMarkdownListItemStyle {
    /// The list item style that places the marker before the content.
    static public var `default`: DefaultMarkdownListItemStyle { .init() }
}

// MARK: - Environment Value

struct MarkdownListItemStyleKey: @preconcurrency EnvironmentKey {
    @MainActor static var defaultValue: any MarkdownListItemStyle = DefaultMarkdownListItemStyle()
}

extension EnvironmentValues {
    var markdownListItemStyle: any MarkdownListItemStyle {
        get { self[MarkdownListItemStyleKey.self] }
        set { self[MarkdownListItemStyleKey.self] = newValue }
    }
}

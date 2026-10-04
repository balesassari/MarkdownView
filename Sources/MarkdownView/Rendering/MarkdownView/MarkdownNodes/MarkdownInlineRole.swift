//
//  MarkdownInlineRole.swift
//  MarkdownView
//

import SwiftUI

/// What an inline run of rendered markdown text stands for.
///
/// MarkdownView tags inline code and links with their role, so a `TextRenderer` can draw them
/// its own way, such as rounded backgrounds behind code or custom link underlines. Read it from
/// a run in `draw(layout:in:)` with `run[MarkdownInlineRole.self]`, and apply the renderer to
/// the markdown view with `textRenderer(_:)`.
public enum MarkdownInlineRole: Hashable, Sendable {
    /// Inline code, such as `` `uploadPending()` ``.
    case inlineCode
    /// The text of a link.
    case link
}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
extension MarkdownInlineRole: TextAttribute { }

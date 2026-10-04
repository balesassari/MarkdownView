//
//  MarkdownCallout.swift
//  MarkdownView
//

import Foundation
import Markdown

/// The kind of a GitHub alert: a block quote whose first line is `[!NOTE]`, `[!TIP]`,
/// `[!IMPORTANT]`, `[!WARNING]` or `[!CAUTION]`.
public enum MarkdownCallout: String, CaseIterable, Hashable, Sendable {
    case note, tip, important, warning, caution

    /// The label GitHub shows at the top of the alert, such as "Note".
    public var title: String {
        rawValue.capitalized
    }
}

extension MarkdownCallout {
    /// Reads the alert marker off a block quote. When the quote's first line is only the
    /// marker (in any case), returns its kind and the quote's blocks without that line;
    /// otherwise no kind and the blocks as they are.
    static func split(_ blockQuote: BlockQuote) -> (callout: MarkdownCallout?, blocks: [any Markup]) {
        let blocks = Array(blockQuote.children)
        guard let paragraph = blocks.first as? Paragraph else { return (nil, blocks) }

        let inlines = Array(paragraph.inlineChildren)
        let lineEnd = inlines.firstIndex { $0 is SoftBreak || $0 is LineBreak } ?? inlines.endIndex
        let marker = inlines[..<lineEnd]
            .map { $0.plainText }
            .joined()
            .trimmingCharacters(in: .whitespaces)
        guard marker.hasPrefix("[!"), marker.hasSuffix("]"),
              let callout = MarkdownCallout(rawValue: marker.dropFirst(2).dropLast().lowercased())
        else { return (nil, blocks) }

        var remaining = Array(blocks.dropFirst())
        let rest = inlines.dropFirst(min(lineEnd + 1, inlines.count))
        if !rest.isEmpty {
            remaining.insert(Paragraph(rest), at: 0)
        }
        return (callout, remaining)
    }
}

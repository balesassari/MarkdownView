//
//  MarkdownBlockItem.swift
//  MarkdownView
//

import Foundation
import Markdown

/// A block to render: a markdown node, or a collapsible section folded out of several.
enum MarkdownBlockItem {
    case markup(any Markup)
    case details(MarkdownDetailsBlock)
}

/// A `<details>` section.
struct MarkdownDetailsBlock {
    /// The summary line as markdown.
    var summary: String
    /// Whether the section starts open, from `<details open>`.
    var isOpen: Bool
    /// What the section holds, which can be more sections.
    var items: [MarkdownBlockItem]
}

extension MarkdownBlockItem {
    /// Folds `<details>` … `</details>` in a run of sibling blocks into sections.
    ///
    /// CommonMark ends an HTML block at the first blank line, so `<details>` and its
    /// `<summary>` usually arrive as one HTML block, the markdown inside as ordinary blocks,
    /// and `</details>` as another HTML block. Written without blank lines, a whole section can
    /// arrive as one HTML block; the text inside it is parsed as markdown here, padded so its
    /// nodes keep their line numbers in the source. A section that is never closed runs to the
    /// end, as in a browser.
    static func group(_ blocks: [any Markup]) -> [MarkdownBlockItem] {
        var root: [MarkdownBlockItem] = []
        var openSections: [PendingDetails] = []

        func append(_ item: MarkdownBlockItem) {
            if openSections.isEmpty {
                root.append(item)
            } else {
                openSections[openSections.count - 1].items.append(item)
            }
        }

        func appendMarkdown(_ source: String, line: Int) {
            let padding = String(repeating: "\n", count: max(line - 1, 0))
            for child in Markdown.Document(parsing: padding + source).children {
                append(.markup(child))
            }
        }

        func closeSection() {
            guard let section = openSections.popLast() else { return }
            append(.details(MarkdownDetailsBlock(
                summary: section.summary ?? "Details",
                isOpen: section.isOpen,
                items: section.items
            )))
        }

        for block in blocks {
            guard let html = block as? HTMLBlock,
                  let tokens = DetailsToken.scan(html.rawHTML) else {
                append(.markup(block))
                continue
            }
            let firstLine = html.range?.lowerBound.line ?? 1
            for (token, lineOffset) in tokens {
                switch token {
                case .open(let isOpen):
                    openSections.append(PendingDetails(isOpen: isOpen))
                case .summary(let summary):
                    if let last = openSections.indices.last,
                       openSections[last].summary == nil,
                       openSections[last].items.isEmpty {
                        openSections[last].summary = summary
                    } else {
                        appendMarkdown(summary, line: firstLine + lineOffset)
                    }
                case .close:
                    closeSection()
                case .markdown(let source):
                    appendMarkdown(source, line: firstLine + lineOffset)
                }
            }
        }
        while !openSections.isEmpty {
            closeSection()
        }
        return root
    }
}

private struct PendingDetails {
    var summary: String?
    var isOpen: Bool
    var items: [MarkdownBlockItem] = []
}

/// The pieces of an HTML block that holds `<details>` tags.
private enum DetailsToken {
    case open(isOpen: Bool)
    case summary(String)
    case close
    /// Text between the tags, rendered as markdown
    case markdown(String)

    /// The tags in `html` in order, with the text between them, each with the number of lines
    /// before it in `html`. Nil when there are no details or summary tags, so the block renders
    /// as it always has.
    static func scan(_ html: String) -> [(token: DetailsToken, lineOffset: Int)]? {
        guard let regex = try? NSRegularExpression(
            pattern: #"<details\b([^>]*)>|</details\s*>|<summary\b[^>]*>(.*?)</summary\s*>"#,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else { return nil }

        let source = html as NSString
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: source.length))
        guard !matches.isEmpty else { return nil }

        var tokens: [(token: DetailsToken, lineOffset: Int)] = []
        var cursor = 0
        func lineOffset(at location: Int) -> Int {
            source.substring(to: location).utf16.reduce(0) { $1 == 0x0A ? $0 + 1 : $0 }
        }
        func appendText(upTo location: Int) {
            let text = source.substring(with: NSRange(location: cursor, length: location - cursor))
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                tokens.append((.markdown(text), lineOffset(at: cursor)))
            }
        }

        for match in matches {
            appendText(upTo: match.range.location)
            let tag = source.substring(with: match.range).lowercased()
            if tag.hasPrefix("</details") {
                tokens.append((.close, lineOffset(at: match.range.location)))
            } else if tag.hasPrefix("<details") {
                let attributes = source.substring(with: match.range(at: 1))
                let isOpen = attributes.range(
                    of: #"\bopen\b"#,
                    options: [.regularExpression, .caseInsensitive]
                ) != nil
                tokens.append((.open(isOpen: isOpen), lineOffset(at: match.range.location)))
            } else {
                let summary = markdownSummary(fromHTML: source.substring(with: match.range(at: 2)))
                if !summary.isEmpty {
                    tokens.append((.summary(summary), lineOffset(at: match.range(at: 2).location)))
                }
            }
            cursor = match.range.location + match.range.length
        }
        appendText(upTo: source.length)
        return tokens
    }

    /// Summary HTML as one line of markdown: code, bold and italic tags turn into markdown and
    /// other tags go. Entities stay, since the markdown parser decodes them.
    private static func markdownSummary(fromHTML html: String) -> String {
        let replacements: [(pattern: String, template: String)] = [
            (#"</?(code|kbd|tt)\b[^>]*>"#, "`"),
            (#"</?(b|strong)\b[^>]*>"#, "**"),
            (#"</?(i|em)\b[^>]*>"#, "_"),
            (#"<[^>]*>"#, ""),
            (#"\s+"#, " "),
        ]
        var text = html
        for replacement in replacements {
            text = text.replacingOccurrences(
                of: replacement.pattern,
                with: replacement.template,
                options: [.regularExpression, .caseInsensitive]
            )
        }
        return text.trimmingCharacters(in: .whitespaces)
    }
}

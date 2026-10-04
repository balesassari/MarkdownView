//
//  MarkdownHighlightedCode.swift
//  MarkdownView
//

import SwiftUI

#if canImport(Highlightr)
@preconcurrency import Highlightr
#endif

/// Syntax-highlighted code, as the default code block style draws it.
///
/// Use it inside a custom ``MarkdownCodeBlockStyle`` to keep MarkdownView's highlighting
/// while drawing your own container. Apply the font and line spacing you want around it.
public struct MarkdownHighlightedCode: View {
    var codeBlockConfiguration: MarkdownCodeBlockStyleConfiguration
    var theme: CodeHighlighterTheme
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var attributedCode: AttributedString?
    @State private var codeHighlightTask: Task<Void, Error>?
    
    /// Creates highlighted code for a code block.
    ///
    /// - Parameters:
    ///   - configuration: The code block a code block style received.
    ///   - theme: The Highlightr themes for light and dark mode.
    public init(
        configuration: MarkdownCodeBlockStyleConfiguration,
        theme: CodeHighlighterTheme = CodeHighlighterTheme(
            lightModeThemeName: "xcode",
            darkModeThemeName: "dark"
        )
    ) {
        self.codeBlockConfiguration = configuration
        self.theme = theme
    }
    
    @_documentation(visibility: internal)
    public var body: some View {
        Group {
            if let attributedCode {
                Text(attributedCode)
            } else {
                Text(verbatim: codeBlockConfiguration.code)
            }
        }
        .task(id: codeHighlightingConfiguration, immediateHighlight)
        .onValueChange(codeBlockConfiguration) {
            debouncedHighlight()
        }
    }
    
    private func debouncedHighlight() {
        codeHighlightTask?.cancel()
        codeHighlightTask = Task.detached(priority: .background) {
            try await updateAttributeCode()
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            try await highlight()
        }
    }
    
    private func updateAttributeCode() async throws {
        guard var attributedCode = attributedCode else { return }
        let characters = attributedCode.characters
        
        for difference in codeBlockConfiguration.code.difference(from: characters) {
            try Task.checkCancellation()
            
            switch difference {
            case .insert(let offset, let insertion, _):
                let insertionPoint = attributedCode.index(
                    attributedCode.startIndex,
                    offsetByCharacters: offset
                )
                attributedCode.insert(
                    AttributedString(String(insertion)),
                    at: insertionPoint
                )
            case .remove(let offset, _, _):
                let removalLowerBound = attributedCode.index(attributedCode.startIndex, offsetByCharacters: offset)
                let removalUpperBound = attributedCode.index(afterCharacter: removalLowerBound)
                attributedCode.removeSubrange(removalLowerBound..<removalUpperBound)
            }
        }
        
        try Task.checkCancellation()
        await MainActor.run {
            self.attributedCode = attributedCode
        }
    }
    
    private func immediateHighlight() async {
        do {
            try await highlight()
        } catch is CancellationError {
            // The task has been cancelled
        } catch {
            logger.error("\(String(describing: error), privacy: .public)")
        }
    }
    
    @Sendable
    nonisolated private func highlight() async throws {
        #if canImport(Highlightr)
        try Task.checkCancellation()
        let highlightr = Highlightr()!
        await highlightr.setTheme(to: theme.themeName(for: colorScheme))
        
        let specifiedLanguage = codeBlockConfiguration.language?.lowercased() ?? ""
        let language = highlightr.supportedLanguages()
            .first(where: { $0.localizedCaseInsensitiveCompare(specifiedLanguage) == .orderedSame })
        
        try Task.checkCancellation()
        
        let code = codeBlockConfiguration.code
        guard let highlightedCode = highlightr.highlight(code, as: language) else { return }
        let attributedCode = NSMutableAttributedString(
            attributedString: highlightedCode
        )
        attributedCode.removeAttribute(.font, range: NSMakeRange(0, attributedCode.length))
        
        try await MainActor.run {
            try Task.checkCancellation()
            self.attributedCode = AttributedString(attributedCode)
        }
        #endif
    }
}

extension MarkdownHighlightedCode {
    struct CodeHighlightingConfiguration: Hashable, Sendable {
        var theme: CodeHighlighterTheme
        var colorScheme: ColorScheme
    }
    
    private var codeHighlightingConfiguration: CodeHighlightingConfiguration {
        CodeHighlightingConfiguration(
            theme: theme,
            colorScheme: colorScheme
        )
    }
}

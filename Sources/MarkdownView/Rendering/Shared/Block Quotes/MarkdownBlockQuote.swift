//
//  MarkdownBlockQuote.swift
//  MarkdownView
//
//  Created by Yanan Li on 2025/2/22.
//

import SwiftUI
import Markdown

struct MarkdownBlockQuote: View {
    var content: MarkdownBlockQuoteStyleConfiguration.Content
    var callout: MarkdownCallout?
    @Environment(\.blockQuoteStyle) private var blockQuoteStyle

    init(content: MarkdownBlockQuoteStyleConfiguration.Content, callout: MarkdownCallout? = nil) {
        self.content = content
        self.callout = callout
    }
    
    var body: some View {
        let configuration = MarkdownBlockQuoteStyleConfiguration(
            content: content,
            callout: callout
        )
        blockQuoteStyle
            .makeBody(configuration: configuration)
            .erasedToAnyView()
    }
}

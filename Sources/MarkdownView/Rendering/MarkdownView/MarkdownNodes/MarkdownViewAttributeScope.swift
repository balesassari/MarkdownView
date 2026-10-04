//
//  MarkdownViewAttributeScope.swift
//  MarkdownView
//
//  Created by Yanan Li on 2025/10/20.
//

import Foundation

extension AttributeScopes {
    struct MarkdownViewAttributeScope: AttributeScope {
        let isHTML: IsHTMLAttribute
        let markdownInlineRole: MarkdownInlineRoleAttribute
    }
}

extension AttributeDynamicLookup {
    subscript<T: AttributedStringKey>(dynamicMember keyPath: KeyPath<AttributeScopes.MarkdownViewAttributeScope, T>) -> T {
        return self[T.self]
    }
}

extension AttributeScopes.MarkdownViewAttributeScope {
    enum IsHTMLAttribute: AttributedStringKey {
        static let name: String = "isHTML"
        
        typealias Value = Bool
    }
}

extension AttributeScopes.MarkdownViewAttributeScope {
    enum MarkdownInlineRoleAttribute: AttributedStringKey {
        static let name: String = "markdownInlineRole"
        
        typealias Value = MarkdownInlineRole
    }
}

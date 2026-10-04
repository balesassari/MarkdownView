import SwiftUI
import Markdown

struct MarkdownList<List: ListItemContainer>: View {
    var listItemsContainer: List
    
    @Environment(\.markdownRendererConfiguration) private var configuration
    @Environment(\.markdownMathContext) private var mathContext
    @Environment(\.markdownElementRenderers) private var elementRenderers
    @Environment(\.markdownListItemStyle) private var listItemStyle
    
    private var marker: Either<AnyUnorderedListMarkerProtocol, AnyOrderedListMarkerProtocol> {
        if listItemsContainer is UnorderedList {
            return .left(configuration.listConfiguration.unorderedListMarker)
        } else if listItemsContainer is OrderedList {
            return .right(configuration.listConfiguration.orderedListMarker)
        } else {
            fatalError("Marker Protocol not implemented for \(type(of: listItemsContainer)).")
        }
    }
    private var depth: Int {
        listItemsContainer.listDepth
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: configuration.componentSpacing) {
            ForEach(
                Array(listItemsContainer.listItems.enumerated()),
                id: \.offset
            ) { (index, listItem) in
                listItemStyle
                    .makeBody(configuration: itemConfiguration(for: listItem, at: index))
                    .erasedToAnyView()
            }
        }
    }
    
    private func itemConfiguration(
        for listItem: ListItem,
        at index: Int
    ) -> MarkdownListItemStyleConfiguration {
        MarkdownListItemStyleConfiguration(
            isOrdered: listItemsContainer is OrderedList,
            index: index,
            ordinal: ordinal(at: index),
            depth: depth,
            checkbox: checkboxState(of: listItem),
            marker: MarkdownListItemStyleConfiguration.Marker(
                CheckboxOrMarker(list: self, listItem: listItem, index: index)
                    .padding(.leading, depth == 0 ? configuration.listConfiguration.leadingIndentation : 0)
            ),
            content: MarkdownListItemStyleConfiguration.Content(
                MarkdownViewRenderer(
                    configuration: configuration,
                    mathContext: mathContext,
                    elementRenderers: elementRenderers
                )
                .makeBody(for: listItem)
            )
        )
    }
    
    private func ordinal(at index: Int) -> Int {
        if let orderedList = listItemsContainer as? OrderedList {
            return Int(orderedList.startIndex) + index
        }
        return index + 1
    }
    
    private func checkboxState(of listItem: ListItem) -> MarkdownListItemStyleConfiguration.Checkbox? {
        switch listItem.checkbox {
        case .some(.checked): .checked
        case .some(.unchecked): .unchecked
        case .none: nil
        }
    }
    
    struct CheckboxOrMarker: View {
        var list: MarkdownList<List>
        var listItem: ListItem
        var index: Int
        
        var body: some View {
            if let checkBox = listItem.checkbox {
                MarkdownCheckbox(checkbox: checkBox)
            } else if case let .left(unorderedMarker) = list.marker {
                SwiftUI.Text(unorderedMarker.marker(listDepth: list.depth))
                    .backdeployedMonospaced(unorderedMarker.monospaced)
            } else if case let .right(orderedMarker) = list.marker {
                SwiftUI.Text(orderedMarker.marker(at: index, listDepth: list.depth))
                    .backdeployedMonospaced(orderedMarker.monospaced)
            }
        }
    }
    
    private struct MarkdownCheckbox: View {
        var checkbox: Checkbox
        
        var body: some View {
            switch checkbox {
            case .checked:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
            case .unchecked:
                Image(systemName: "circle")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Auxiliary

fileprivate extension SwiftUI.Text {
    func backdeployedMonospaced(_ isActive: Bool = true) -> SwiftUI.Text {
        if #available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *) {
            return monospaced(isActive)
        } else {
            @Environment(\.font) var font
            return self.font(font?.monospaced())
        }
    }
}

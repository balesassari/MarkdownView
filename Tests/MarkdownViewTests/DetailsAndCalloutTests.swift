import Markdown
import Testing

@testable import MarkdownView

@Suite("Collapsible sections and callouts")
struct DetailsAndCalloutTests {
    private func items(_ source: String) -> [MarkdownBlockItem] {
        MarkdownBlockItem.group(Array(Markdown.Document(parsing: source).children))
    }

    @Test("Folds a section written with blank lines, the way GitHub's template is")
    func foldsSectionWithBlankLines() throws {
        let items = items("<details>\n<summary>Logs</summary>\n\nSome text\n\n</details>\n\nAfter")
        #expect(items.count == 2)
        guard case .details(let details) = try #require(items.first) else {
            Issue.record("Expected a collapsible section")
            return
        }
        #expect(details.summary == "Logs")
        #expect(details.isOpen == false)
        #expect(details.items.count == 1)
    }

    @Test("Folds a section written as one HTML block, and parses the markdown inside it")
    func foldsSingleBlockSection() throws {
        let items = items("<details open>\n<summary><code>run()</code> output</summary>\nSome **text**\n</details>")
        #expect(items.count == 1)
        guard case .details(let details) = try #require(items.first) else {
            Issue.record("Expected a collapsible section")
            return
        }
        #expect(details.summary == "`run()` output")
        #expect(details.isOpen)
        guard case .markup(let markup) = try #require(details.items.first) else {
            Issue.record("Expected markdown inside the section")
            return
        }
        #expect(markup is Markdown.Paragraph)
    }

    @Test("Nests sections, and runs an unclosed section to the end")
    func nestsSections() throws {
        let items = items("""
        <details>
        <summary>Outer</summary>

        <details>
        <summary>Inner</summary>

        Text

        </details>

        More
        """)
        #expect(items.count == 1)
        guard case .details(let outer) = try #require(items.first) else {
            Issue.record("Expected the outer section")
            return
        }
        #expect(outer.summary == "Outer")
        #expect(outer.items.count == 2)
        guard case .details(let inner) = try #require(outer.items.first) else {
            Issue.record("Expected the inner section")
            return
        }
        #expect(inner.summary == "Inner")
    }

    @Test("Names a section without a summary Details")
    func defaultsSummary() throws {
        let items = items("<details>\n\nText\n\n</details>")
        guard case .details(let details) = try #require(items.first) else {
            Issue.record("Expected a collapsible section")
            return
        }
        #expect(details.summary == "Details")
    }

    @Test("Leaves other HTML blocks alone")
    func leavesOtherHTML() throws {
        let items = items("<div>Hi</div>")
        guard case .markup(let markup) = try #require(items.first) else {
            Issue.record("Expected the HTML block")
            return
        }
        #expect(markup is Markdown.HTMLBlock)
    }

    @Test(
        "Reads a GitHub alert marker and drops its line",
        arguments: [("[!NOTE]", MarkdownCallout.note), ("[!warning]", .warning), ("[!CAUTION]", .caution)]
    )
    func readsCallout(marker: String, callout: MarkdownCallout) throws {
        let document = Markdown.Document(parsing: "> \(marker)\n> Keep a backup.")
        let quote = try #require(document.child(at: 0) as? Markdown.BlockQuote)
        let split = MarkdownCallout.split(quote)
        #expect(split.callout == callout)
        #expect(split.blocks.count == 1)
        #expect((split.blocks.first as? Markdown.Paragraph)?.plainText == "Keep a backup.")
    }

    @Test("Keeps an ordinary quote as it is")
    func keepsOrdinaryQuote() throws {
        let document = Markdown.Document(parsing: "> [!NOTE] is how alerts start.")
        let quote = try #require(document.child(at: 0) as? Markdown.BlockQuote)
        let split = MarkdownCallout.split(quote)
        #expect(split.callout == nil)
        #expect(split.blocks.count == 1)
    }
}

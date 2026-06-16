import Testing
import CoreGraphics
@testable import ProducerBuddy

@Suite("Share Cards")
struct ShareCardTests {

    @Test("Square format is 1:1")
    func squareIsSquare() {
        let size = CardFormat.square.size
        #expect(size.width == size.height)
    }

    @Test("Story format is portrait and taller than square")
    func storyIsPortrait() {
        let story = CardFormat.story.size
        #expect(story.height > story.width)
        #expect(story.height > CardFormat.square.size.height)
    }

    @Test("Story aspect ratio is close to 9:16")
    func storyAspectRatio() {
        let story = CardFormat.story.size
        let ratio = story.width / story.height
        #expect(abs(ratio - 9.0 / 16.0) < 0.02)
    }

    @Test("Both formats are offered to the user")
    func allFormatsAvailable() {
        #expect(CardFormat.allCases.count == 2)
    }
}

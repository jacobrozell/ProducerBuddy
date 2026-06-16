import Foundation
import Testing
@testable import MixStack

@Suite("Library filter logic")
struct LibraryFilterTests {
  @Test("BPM range filter respects min and max")
  func bpmRange() {
    let song = Song(title: "House", bpm: 124)
    #expect(LibraryFilterLogic.matchesBPMRange(song: song, min: 60, max: 200))
    #expect(LibraryFilterLogic.matchesBPMRange(song: song, min: 120, max: 128))
    #expect(!LibraryFilterLogic.matchesBPMRange(song: song, min: 130, max: 140))
  }

  @Test("BPM section bucket for 124 BPM")
  func bpmSection() {
    #expect(LibraryFilterLogic.bpmSectionTitle(for: 124) == "110–128 BPM")
    #expect(LibraryFilterLogic.bpmSectionTitle(for: 85) == "60–90 BPM")
    #expect(LibraryFilterLogic.bpmSectionTitle(for: 160) == "150+ BPM")
  }

  @Test("Rating section titles")
  func ratingSection() {
    #expect(LibraryFilterLogic.ratingSectionTitle(for: 5) == "5★")
    #expect(LibraryFilterLogic.ratingSectionTitle(for: 0) == "Unrated")
  }

  @Test("Key filter passes when empty or matching")
  func keyFilter() {
    let song = Song(title: "A", key: .aMinor)
    #expect(LibraryFilterLogic.matchesKeyFilter(song: song, selectedKeys: []))
    #expect(LibraryFilterLogic.matchesKeyFilter(song: song, selectedKeys: [.aMinor]))
    #expect(!LibraryFilterLogic.matchesKeyFilter(song: song, selectedKeys: [.cMajor]))
  }

  @Test("Search includes notes")
  func searchNotes() {
    let song = Song(title: "Beat", notes: "FL export v3")
    #expect(LibraryFilterLogic.matchesSearch(song: song, query: "export"))
    #expect(!LibraryFilterLogic.matchesSearch(song: song, query: "remix"))
  }

  @Test("Combined filters use AND logic")
  func combinedFilters() {
    let song = Song(title: "Track", bpm: 128, key: .aMinor, category: .workInProgress)
    song.isFavorite = true
    song.vocalPresence = VocalPresence.instrumental
    song.vocalConfidence = 0.9

    let passes = LibraryFilterLogic.matchesBPMRange(song: song, min: 120, max: 130)
      && LibraryFilterLogic.matchesKeyFilter(song: song, selectedKeys: [.aMinor])
      && LibraryFilterLogic.matchesFavoritesOnly(song: song, favoritesOnly: true)
      && song.matches(vocalFilter: VocalLibraryFilter.instrumental)
    #expect(passes)
  }

  @Test("BPM sort groups into ordered sections")
  func bpmSections() {
    let slow = Song(title: "Slow", bpm: 80)
    let mid = Song(title: "Mid", bpm: 124)
    let sections = LibraryFilterLogic.sections(
      for: [mid, slow],
      sort: .bpm
    )
    #expect(sections.count == 2)
    #expect(sections[0].title == "60–90 BPM")
    #expect(sections[1].title == "110–128 BPM")
  }
}

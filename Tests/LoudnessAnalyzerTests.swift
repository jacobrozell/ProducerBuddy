import Testing
@testable import MixStack

@Suite("Loudness analyzer")
struct LoudnessAnalyzerTests {
    @Test("Silence returns no loudness")
    func silenceReturnsNil() {
        let samples = [Float](repeating: 0, count: 44_100)
        #expect(LoudnessAnalyzer.estimateIntegratedLUFS(samples: samples, sampleRate: 44_100) == nil)
    }

    @Test("Steady tone yields a negative LUFS estimate")
    func toneIsNegativeLUFS() {
        let samples = [Float](repeating: 0.25, count: 44_100)
        let lufs = LoudnessAnalyzer.estimateIntegratedLUFS(samples: samples, sampleRate: 44_100)
        #expect(lufs != nil)
        if let lufs {
            #expect(lufs < 0)
            #expect(lufs > -40)
        }
    }

    @Test("Louder tone reads hotter than quieter tone")
    func louderReadsHotter() {
        let quiet = [Float](repeating: 0.1, count: 88_200)
        let loud = [Float](repeating: 0.4, count: 88_200)
        let quietLUFS = LoudnessAnalyzer.estimateIntegratedLUFS(samples: quiet, sampleRate: 44_100)
        let loudLUFS = LoudnessAnalyzer.estimateIntegratedLUFS(samples: loud, sampleRate: 44_100)
        #expect(quietLUFS != nil)
        #expect(loudLUFS != nil)
        if let quietLUFS, let loudLUFS {
            #expect(loudLUFS > quietLUFS)
        }
    }
}

@Suite("Loudness semantics")
struct LoudnessSemanticsTests {
    @Test("Streaming ballpark copy covers mid targets")
    func ballparkCopy() {
        #expect(LoudnessSemantics.guidance(for: -14).contains("ballpark"))
        #expect(LoudnessSemantics.isCaution(lufs: -14) == false)
        #expect(LoudnessSemantics.isCaution(lufs: -8) == true)
    }
}

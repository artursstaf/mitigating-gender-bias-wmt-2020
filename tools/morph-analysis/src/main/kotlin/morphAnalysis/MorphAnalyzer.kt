package morphAnalysis

import edu.stanford.nlp.ie.ner.CMMClassifier
import edu.stanford.nlp.ling.CoreAnnotations
import edu.stanford.nlp.ling.CoreLabel
import edu.stanford.nlp.sequences.LVMorphologyReaderAndWriter
import me.tongfei.progressbar.ProgressBar
import java.io.File
import java.io.PrintWriter

data class Token(val text: String, var features: String = "")

class MorphAnalyzer {
    private val analyzer = LVMorphologyReaderAndWriter.getAnalyzer()
    private val classifier = CMMClassifier.getClassifier("models/lv-morpho-model.ser.gz")

    init {
        analyzer.describe(PrintWriter(System.err))
        LVMorphologyReaderAndWriter.setPreloadedAnalyzer(analyzer)
    }

    fun analyze(sentences: List<List<Token>>) {
        for (sent in ProgressBar.wrap(sentences, "Sentences")) {
            var morphologyTokens: List<CoreLabel> =
                LVMorphologyReaderAndWriter.analyzeSentence2(sent.map { analyzer.analyze(it.text) })
            morphologyTokens = (classifier.classify(morphologyTokens) as List<CoreLabel>)

            val sentTokenInterator = sent.iterator()
            for (morphologyToken in morphologyTokens) {
                if (morphologyToken.getString(CoreAnnotations.TextAnnotation::class.java).contains("<s>")) {
                    continue
                }
                val token = sentTokenInterator.next()
                val analysis = morphologyToken.get(CoreAnnotations.LVMorphologyAnalysis::class.java)
                val mainWordForm = analysis.getMatchingWordform(
                    morphologyToken.get(CoreAnnotations.AnswerAnnotation::class.java),
                    false
                )
                if (mainWordForm != null) {
                    token.features = mainWordForm.pipeDelimitedEntries().toString()
                }

            }
        }
    }
}

fun getGender(t: Token): Char {
    val key = "Dzimte="
    if (t.features.indexOf(key) != -1) {
        return when (t.features[t.features.indexOf(key) + key.length]) {
            'V' -> 'M'
            'S' -> 'F'
            else -> 'U'
        }
    }
    return 'U'
}

fun main(args: Array<String>) {
    val inputFile = File(args[0])
    val outputFile = File(args[1])

    val sentences = inputFile.readLines().map { it.split(" ").map { Token(it) } }

    MorphAnalyzer().analyze(sentences)

    val text = sentences.joinToString(separator = "\n", postfix = "\n") { sentence ->
        sentence.map { getGender(it) }.joinToString(separator = " ")
    }

    outputFile.writeText(text)
}
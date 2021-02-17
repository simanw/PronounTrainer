# Load your usual SpaCy model (one of SpaCy English models)
import spacy
nlp = spacy.load('en')
# load NeuralCoref and add it to the pipe of SpaCy's model
import neuralcoref

class Model:
    def __init__(self):
        coref = neuralcoref.NeuralCoref(nlp.vocab)
        nlp.add_pipe(coref, name='neuralcoref')
        print("Model loaded")

    def resolve(self, text):
        doc = nlp(text)
        return doc
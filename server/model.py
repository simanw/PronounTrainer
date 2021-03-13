from loguru import logger
# Load your usual SpaCy model (one of SpaCy English models)
import spacy
nlp = spacy.load('en')
# load NeuralCoref and add it to the pipe of SpaCy's model
import neuralcoref

class Model:
    def __init__(self):
        coref = neuralcoref.NeuralCoref(nlp.vocab)
        nlp.add_pipe(coref, name='neuralcoref')
        logger.info("Model loaded")

    def resolve(self, text):
        return nlp(text)
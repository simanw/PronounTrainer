import neuralcoref
import json
from loguru import logger
from model import Model

class Filter:

    def __init__(self):
        self.model = Model()
        self.response = None

    def on_get(self, msgs):
        self.response = {}
        text = self.bytes_to_text(msgs)
        doc = self.model.resolve(text)
        return self.doc_to_jsonStr(doc)

    def doc_to_jsonStr(self, doc):
        if doc._.has_coref:
                mentions = [
                    {
                        "start": mention.start_char,
                        "end": mention.end_char,
                        "text": mention.text,
                        "resolved": cluster.main.text,
                    }
                    for cluster in doc._.coref_clusters
                    for mention in cluster.mentions
                ]
                clusters = list(
                    list(span.text for span in cluster)
                    for cluster in doc._.coref_clusters
                )
                resolved = doc._.coref_resolved
                self.response["mentions"] = mentions
                self.response["clusters"] = clusters
                self.response["resolved"] = resolved
        body = json.dumps(self.response, indent=4)
        logger.debug(f'Contain coref? {doc._.has_coref}. Formatted Result: {body}')
        return body

    def bytes_to_text(self, input):
        string = input.decode('utf-8-sig')
        string = json.loads(string)
        logger.debug(f'Decoded string: {string}')
        return string

import neuralcoref
import json
from model import Model
# a list of object -> json clusters2Json
# log()

class Filter:

    def __init__(self):
        # initialize log
        self.model = Model()
        self.response = None

    def on_get(self, msgs):
        self.response = {}
        text = self.msg_to_text(msgs)
        doc = self.model.resolve(text)
        return self.doc_to_json(doc)

    def doc_to_json(self, doc):
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
        print(body)
        return body.encode('utf-8')

    def msg_to_text(self, input):
        return input

# Pronoun Trainer


## Coreference Resolution Websocket Server
### Architecture
#### Scheme 1
    - Maintain 1 nlp model
    - Maintain a set of client sockets
    - All clients serially request resolved result from the single nlp model

#### Scheme 2
    - Maintain 1 nlp model
    - Maintain a set of client sockets
    - All clients concurrently request resolved result from the single nlp model
  
#### Scheme 3
    - Maintain 10 nlp models, each one running in a thread
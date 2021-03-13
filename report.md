# Pronoun Trainer

## Introduction
### Background
The motivation of this project originates from a problem I frequently run into when communicating with people in LGBTQ community. My roommate's daughter is bisexual and active in the local LGBTQ community. My roommate and I often contact with people who prefer gender-neutral pronouns via his daughter. During pandemic, online chatting happens much more frequently than in-person conversation. It is common to mention people unconsciously though not intentionally with unwelcoming pronouns due to gender stereotype. As the experiences of people who don’t identify as a man or a woman have gained attention, it is necessary to get used to gender-neutral pronouns to show respect and politeness.

Some surveys and news releases indicate a trend that gender-neutral pronouns have gained more attention as equity on the basis of gender identity become more concerned.

According to a Pew Research Center survey conducted in fall 2018, about one-in-five Americans say they personally know someone preferrs gender-neutral pronouns such as “they” instead of “he” or “she”. Roughly three-quarters of Americans ages 18 to 29 (73%) say they have heard a little or a lot about people preferring nonbinary pronouns, compared with about two-thirds of those 30 to 49 (65%) and smaller shares of those ages 50 to 64 (54%) and 65 and older (46%). Besides, there are notable differences by age and party on whether Americans feel comfortable using gender-neutral pronouns to address those who ask for it, with young adults and Democrats more likely than older Americans and Republicans to express comfort. 
 
Recently, in the 117th Congress, Democrats defend a provision in the House rules package that honors "all gender identities by changing pronouns and familial relationships in the House rules to be gender neutral.” For example, the familial terms father, mother, son, daughter, brother, sister, uncle, aunt are to be replaced with gender-neutral terminology, such as parent, child, sibling, parent’s sibling.

Given this trend and my personal experience in communication with LGBTQ community, people need external helps to fit in this fasion of referring to others with gender-neutral pronouns. I paid most attention to mobile instant messaging apps where mentioning a third person with unpreferred pronouns frequently happens. The project includes an iOS instant messaging app that instantly detects misused pronouns and alerts users, with help of an advanced NLP model that resolves corefences and an edge computing platform that provides real time responsiveeness. 

The contributions are:
1. Developed an iOS instant messaging app that is able to instantly detect unpreferred pronouns when users mention people in a chat room.
2. Built a containerized coreference resolution model server that supports pairing up names and mentions in a text in miliseconds-level responsiveness.
3. Deployed instant messaging backend server and coreference resolution model server at the egde of clouds backed by OpenStack StarlingX.


### Coreference Resolution
Coreference resolution is the task of finding all expressions that refer to the same entity in a text. It is an important step for a lot of higher level NLP tasks that involve natural language understanding such as document summarization, question answering, and information extraction.

Coreference is a rather old NLP research topic [1]. It has seen a shifting trend, from methods completely dependent on hand-crafted features to deep learning based approaches, which attempt to learn feature representations and are loosely based on hand-engineered features. It has seen a revival of interest in the past few years as several research groups applied cutting-edge deep-learning and reinforcement-learning techniques to it. It was published that coreference resolution may be instrumental in improving the performances of NLP neural architectures like RNN and LSTM.

There is a diversity of open source tools for the task based on various algorithms. Stanford coref toolkit provides 3 models which were pioneered by the Stanford NLP group. These three algorithms are Deterministic, Statistical and Neural. This tool is wrapped up in a JAVA library. Hugging Face is an AI community that build, train and deploy state of the art models powered by the reference open source in natural language processing. They provide NeuralCoref, a neural coreference resolution system, and demostrate a live demo. The model can be easily installed and used as a Python module. Since NeuralCoref came out after Stanford coref toolkit, it maintains user-friendly APIs and documentation, and the community keep active, I decided to employ NerualCoref in the project. 

### Edge Computing

Edge computing describes a computing topology in which information processing and content collection and delivery are placed closer to the sources, repositories and consumers of this information. Edge computing draws from the concepts of distributed processing. It tries to keep the traffic and processing local to reduce latency, exploit the capabilities of the edge and enable greater autonomy at the edge.

Some workloads are beginning to move to the edge rather than a traditional cloud. AI, ML, and IoT are currently the key technologies driving this change. These technologies increasingly leverage larger local datasets, which makes it necessary to process data right where it’s created rather than sending to the cloud and back.

At present, many open source edge computing platforms have emerged. EdgeXFoundary, launched in April 2017, is a Linux foundation common open platform for IoT edge computing. Akraino, initiated by AT&T and Intel in Feb 2018, is a Linux foundation project for carrier-scale edge computing applications running in virtual machines and containers. OpenStack StarlingX, jointly open sourced by Intel and Wind River in October 2018, is an OpenStack foundation project that run the minimal services required at the edge, yet provide robust support for bare metal, container technologies and virtual machines. There are several projects under Eclipse Foundation supports IoT and Edge platforms, such as Eclipse foundation cloud platform stack, Eclipse foundation IoT working group and Eclipse foundation with CNCF for IoT Edge. 

Among these open platforms, StarlingX and Arkraino have the top two active communities and they are aligned with each other. Besides, Starlingx provides structured documentation and fully integrated well known components such as OpenStack modules, Kubernetes, Ceph, OVS-DPDK and so forth. Thus, StarlingX is chosen in this project as the environment of backend servers.

## Solution
### Architecture Overview

### Server
#### Instant Messaging Server
I used Tinode instant messaging server implemented in pure Go. Its wire transport is JSON over websocket (long polling is also available) for custom bindings, or protobuf with gRPC. It provides three persistent storage options: RethinkDB, MySQL and MongoDB, among which I chose MySQL. A third-party unsupported DynamoDB adapter also exists. Other databases can be supported by writing custom adapters. The backend services can be installed and deployed using Docker as the server and the database are both well-defined in images and accessible on Docker Hub.

#### Coreference Resolution Server
Coreference resolution backend server is implemented in Python. It contains three major components: websocket server, data filter and coreference resolution model.

Websocket server depends on an open source package websockets to manage websocket connections. Built on top of asyncio, Python’s standard asynchronous I/O framework, websockets provides an elegant coroutine-based API.  Websocket server communicates with the client via bytes daya encoded by UTF-8. Besides, the server is able to maintain multiple websocket connections at the same time.

Data filter acts as a data formater between the websocket server and the NLP model. As mentioned above, the websocket server receives bytes data from the client. Data filter transfers bytes to strings by decoding it with UTF-8. The decoded string then is sent to the coreference resolution model. The model returns an object that wraps up the resolved result. Data filter transfers the object to a JSON object, and then encode it to a string. By the end, data filter outputs a JSON string to the websocket server.

Coreference resolution model is built based on NeuralCoref. NeuralCoref is a pipeline extension for spaCy 2.1+ which annotates and resolves coreference clusters using a neural network. NeuralCoref is production-ready, integrated in spaCy's NLP pipeline and extensible to new training datasets. NeuralCoref is written in Python/Cython and comes with a pre-trained statistical model for English only. For simplicity, the pre-trained English-only model is used as the coreference resolution model. It is allowed to control the behavior of NeuralCoref by passing configurable parameters to it.

Specifically, NeuralCoref resolves the coreferences and annotate them as extension attributes in the spaCy Doc, Span and Token objects under the ._. dictionary. Generally, clusters of corefering mentions in the doc are mostly concerned. Cluster has a list of all the mentions. Each mention stores detailed useful information, for instance, start position and end position of the mention.

### Client
The client is based on Tinode iOS. Tinode iOS is an open source instant messaging iOS application. It supports user login, user register, one-on-one chatting, group chatting, transport level security (https/wss), local data persistence and so on. 

Mobile instant messaging app has complicated business logic and data flow. For simplicty, the workflow only related to pronouns is mentioned here: 
    1. Once the user taps send button, the message in the text field along with chat history as the context are sent to the coreference resolution server.
    2. The client keeps listening to response from the server until the server has done computing pairwise ranking of all anticedent-mention pairs and sending back the resolved result.
    3. Once receiving the response, the client decodes it and checks if any mismatched name-mention pair exists in the message that the user just typed in.
    4. If any misused pronouns for a name is detected, an alert view is triggered to diplay warnings.

These screenshots demonstrate the workflow:

The following section specificly decribes implementation details.

1. Add pronouns label to user 
Since pronouns are essential in the use case, choosing preferred pronouns is mandatory when a new user signs up. According to Tinode iOS, `VCard`, a model, stores all of information of a user, including login token, fullname, avatar, contact, etc. `VCard` is serialized and encoded as JSON when it is stored to the local MySQL database. This allows me to add a pronoun field to `VCard` without worring about modify the scheme of MySQL database. 

2. Communicate with the coreference resolution backend server
While class Tinode communicates with the instant messaging server, class `Coref` handles websocket connection and communicates with the coreference resolution backend server. Tinode iOS encapsulates websocket connection in Connection class using SwiftWebsocket package as its websocket support. I built Coref based on Connection to ensure simplicity and consistency though SwiftWebsocket is no longer maintained. Coref has a dependency connectionListener that listens to connection events (e.g. onConnect, onMessage, onError). Coref maintains listenerNotifier that broadcasts resolved result to all downstream listeners. 

3. Detect misused pronouns
`MisusedPronounDetector` handles the business logic of detecting misused pronouns in the message. To ensure the detector works, there have to be some strong assumptions:
    - Each user provides fullname when signing up.
    - Only consider those in the contact list of the user when searching people who are mentioned with wrong pronouns.
    - The user mentions a person with the person's first name instead of short nickname.
MisusedPronounDetector has a dependency contactManager that is able to fetch contacts of the user. MisusedPronounDetector creates a mapping from a contact's first name to preferred prounouns when it is instanciated. Considering the user possibly adds new contacts when running the app, misusedPronounDetector also exposes an interface to update the mapping. Regarding misused pronouns detection, the resolved result contains all name-pronoun pairs in the context and the text just typed in. Name-pronoun pairs in the context are discarded because only misused pronouns appear in the text are concerned. Besides, those pairs whoes names aren't included in the mapping are discarded as well.

4. User Interfaces
Since Tinode iOS was started before SwiftUI came out in September 2019, its architecture applies MVC (Model-View-Controller) pattern. `MessageViewController` is the view controller I mostly worked on. It mainly coordinates the flow of information between the app’s local storage, which encapsulates the app’s data and persists data in SQLite, and the views that display messages and alerts, manages the life cycle of its content views, and implements the behavior to respond to user input like sending messages and uploading attachments. 

MessageViewController is the most massive view controller in this app. It has a dependency instance of `MessageInteractor` that listens to events incurred by Tinode and Coref, and specifically handles business logic of sending and displaying messages and any other related features. To let MessageInteractor be able to deal with displaying misused pronouns alert, MessageInteractor conforms to `PronounAlertBusinessLogic` protocol that defines a blueprint of alert display. More specifically, MessageInteractor calls an instance method of `MessagePresenter`, which encapsulates details of displaying contents. `MessagePresenter` adopts some protocols that define presentation logic. `MessagePresenter` takes messageViewController itself as the delegate. Once messageViewController is called to display alerts, it instanciates an alertViewController and present the alert information.

5. Others
I applied singleton pattern to restrict the instantiation of Tinode, Coref and `MisusedPronounDetector`. They are instantiated when the app is lauched. This is useful when exactly one object is needed to coordinate actions across the system. Ensuring a single instance of MisusedPronounDetector allows to dynamically update name-pronouns mapping when the user adds new contacts while running the app. 

### Containerized Application Deployment

Build docker image

StarlingX R4.0 is the latest stable release. StarlingX provides a pre-defined set of standard deployment configurations. Most deployment options may be installed in a virtual environment or on bare metal. For sake of simplicity and hardware support, I chose Virtual All-in-one Simplex configuration. The All-in-one Simplex (AIO-SX) deployment option provides all three cloud functions (controller, worker, and storage) on a single server with the benefits: requires only a small amount of cloud processing and storage power, application consolidation using multiple containers or virtual machines on a single pair of physical servers, and a storage backend solution using a single-node CEPH deployment.

Machine set up
    - Install OpenStack StarlingX platform on the machine
    - chose All-in-one simplex configuration
    - upload images to the local docker registry


## Result

The app is tested on iPhone 7 and iPhone 12 Pro Max seperately.


## Discussion
### Bias in NLP Model
This is resulted from the fact that gender has become a direction of main variance of NeuralCoref's trained word vectors. Hugging Face trained the word embedding on a large coreference anotated dataset without supplying any information regarding word gender. The outcome is shown below.


On the left, the original word2vec words vectors don’t specifically care about gender association. On the right side, after training, the word vectors shows feminine and masculine nouns nicely separated along the principal components of the vectors even though word gender information was not provided (gender has become a direction of main variance of our trained word vectors).

NeuralCoref embeddings are trained on the OntoNotes 5.0 dataset. This dataset has an obvious flaw. It is built mainly from news and web articles hence with a more formal language than the usual casual talks.

### Language ambiguity in informal talks


### Further Work
The ideal solution is to keep sending message to server and analyzing resolved result back from the server while the user is typing. 

But if there are many users typing simultaneously, which does happen, the server's gonna die. Of course, load balancer and other techniques in distributed system can solve this problem. But it introduces unnecessary difficulties in this demo app.

There are two alternatives:
1. A set of clients concurrently request resolved result from the single NLP model.
2. A set of clients request resolved result from multiple NLP model that parallelly run in different threads.

From my point of view, the latter could apply producer-consumer strategy. However, it is a tough task since it mixes asynchronous programming with multithreading. 


## Reference



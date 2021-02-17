#!/usr/bin/env python
import websockets
import asyncio
from websocketServer import *


def main():
    start_server = websockets.serve(resolve, "localhost", 5001)
    asyncio.get_event_loop().run_until_complete(start_server)
    asyncio.get_event_loop().run_forever()

if __name__ == '__main__':
    main()

#!/usr/bin/env python
import websockets
import asyncio
from websocketServer import *


def main():
    loop = asyncio.get_event_loop()
    try:
        start_server = websockets.serve(handle_socket_connection, "localhost", 5050)
        print(f'Started socket server: {start_server} ...')
        asyncio.get_event_loop().run_until_complete(start_server)
        asyncio.get_event_loop().run_forever()
    finally:
        loop.close()
        print(f"Succuessfully shut down [{loop}].")

if __name__ == '__main__':
    main()

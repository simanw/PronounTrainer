#!/usr/bin/env python
import websockets
import asyncio
import sys
from loguru import logger
from websocketServer import *


def main():
    loop = asyncio.get_event_loop()
    try:
        start_server = websockets.serve(handle_socket_connection, "localhost", 5050)

        logger.info(f'Started socket server: {start_server} ...')
        asyncio.get_event_loop().run_until_complete(start_server)
        asyncio.get_event_loop().run_forever()
    finally:
        loop.close()
        logger.success(f'Succuessfully shut down [{loop}].')

if __name__ == '__main__':
    logger.add("./log/out.log", rotation="500 MB", format="{time:YYYY-MM-DD at HH:mm:ss} | {level} | {message}", level="INFO")
    logger.add(sys.stderr, level="DEBUG")
    main()

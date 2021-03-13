import asyncio
import websockets
import time
from loguru import logger
from filter import *
    
filter = Filter()
websocket_clients = set()

async def handle_socket_connection(websocket, path):
    """
    Handles the whole lifecycle of each client's websocket connection.
    """
    websocket_clients.add(websocket)
    logger.info(f'New connection from: {websocket.remote_address} ({len(websocket_clients)} total)')
    try:
        # This loop will keep listening on the socket until its closed. 
        async for msg in websocket:
            logger.info(f"< from {websocket.remote_address} Raw text: {msg}")
            json = filter.on_get(msg)
            logger.opt(record=True, colors=True).info("Model has done resolution in thread: <blue>{record[thread]}</blue>")
            task = asyncio.create_task(websocket.send(json))
            await task
            logger.info(f"> Sent back resolved result to {websocket.remote_address}")
    except websockets.exceptions.ConnectionClosedError as cce:
        logger.error("Connection Closed Error")
    finally:
        logger.info(f'Disconnected from socket [{id(websocket)}]...')
        websocket_clients.remove(websocket)
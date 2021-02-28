import asyncio
import websockets
import time
from filter import *
    
filter = Filter()
websocket_clients = set()

async def handle_socket_connection(websocket, path):
    """
    Handles the whole lifecycle of each client's websocket connection.
    """
    websocket_clients.add(websocket)
    print(f'New connection from: {websocket.remote_address} ({len(websocket_clients)} total)')
    try:
        # This loop will keep listening on the socket until its closed. 
        async for msg in websocket:
            print(f"< [{time.strftime('%a, %d %b %Y %H:%M:%S', time.gmtime())}] from {websocket.remote_address} message: {msg}")
            json = filter.on_get(msg)
            task = asyncio.create_task(websocket.send(json))
            await task
            print(f"> [{time.strftime('%a, %d %b %Y %H:%M:%S', time.gmtime())}] Sent back resolved result to {websocket.remote_address}")
    except websockets.exceptions.ConnectionClosedError as cce:
        pass
    finally:
        print(f'Disconnected from socket [{id(websocket)}]...')
        websocket_clients.remove(websocket)
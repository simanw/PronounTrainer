import asyncio
import websockets
from filter import *
    
filter = Filter()

async def resolve(websocket, path):
    async for msg in websocket:
        print(f"< {msg}")
        json = filter.on_get(msg)
        await websocket.send(json)
        print(f"> sent back json")
import factorio_rcon
import json

SERVER_IP = "127.0.0.1"
RCON_PORT = 41941
RCON_PASSWORD = "rcon"

def rcon_get_state() -> dict:
    """Get the current state of the agent from factorio.
    
    Uses factorio_rcon for raw communication to the game instance, sending custom interface 
    commands. Data from factorio is written to disk, where it is read, preprocessed, and returned.
    
    Returns:
        dict: Dictionary containing all state information
    """
    
    client = factorio_rcon.RCONClient(SERVER_IP, RCON_PORT, RCON_PASSWORD)
    response = client.send_command("/windfish-state")
    result = response.split('\n')
    result = [json.loads(r) for r in result]
    
    return {
        "world": result[0],
        "object": result[1],
        "agent": result[2]
    }
    
def rcon_act(action_id: int, item_id: int) -> bool:
    client = factorio_rcon.RCONClient(SERVER_IP, RCON_PORT, RCON_PASSWORD)
    response = client.send_command(f"/windfish-act {action_id} {item_id}")
    print(response)
    
def rcon_enable_botmode():
    client = factorio_rcon.RCONClient(SERVER_IP, RCON_PORT, RCON_PASSWORD)
    client.send_command(f"/windfish-toggle-botmode true")

def rcon_disable_botmode():
    client = factorio_rcon.RCONClient(SERVER_IP, RCON_PORT, RCON_PASSWORD)
    client.send_command(f"/windfish-toggle-botmode false")
    
def rcon_reset_position():
    client = factorio_rcon.RCONClient(SERVER_IP, RCON_PORT, RCON_PASSWORD)
    client.send_command(f"/windfish-reset-pos")
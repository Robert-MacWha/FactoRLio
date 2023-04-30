import factorio_rcon

SERVER_IP = "127.0.0.1"
RCON_PORT = 41941
RCON_PASSWORD = "rcon"
client = factorio_rcon.RCONClient(SERVER_IP, RCON_PORT, RCON_PASSWORD)

response = client.send_command("/c remote.call('windfish', 'test', 'Hello World!')")
print(response)
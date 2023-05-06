from src import Agent, rcon_get_state, rcon_act, rcon_enable_botmode, rcon_disable_botmode, rcon_reset_position

# agent = Agent()

# rcon_disable_botmode()
# while True:
#     # state = rcon_get_state()
#     # print(state)
    
#     action = agent.act()

#     rcon_act(5, action[1])

rcon_disable_botmode()
rcon_reset_position()
rcon_act(11, 4)
import random

class Agent:
    """FactoRLio agent
    
    Communication with factorio is described in-depth in the README.  A summary is 
    listed below:
     - State space: Three primary modalities are provided for the state space.  Viewport 
     maps containing spacial information (IE tiles, objects) are presented as 3d arrays. 
     The agent's inventory is presented as a 1d array of item quantities.  Finally, 
     information about the object the agent is facing is presented in a list of 1d arrays.
     - Action space: One of nine actions can be preformed each tick, selected from the 
     list of actions (move n/e/s/w, destroy, craft, place, insert, and extract).  Each 
     action will have an acompanying item selected by a one-hot selector, which will 
     determin what is crafted, placed, inserted, or extracted.     
    """
    
    def __init__(self):
        pass
    
    def act(self) -> tuple[int, int]:
        """Query the agent and return the selected action

        Returns:
            tuple[int, int]: Tuple action to take: [action_index, item_index]
        """
        
        return (
            random.randint(0, 3),
            random.randint(1, 20)
        )

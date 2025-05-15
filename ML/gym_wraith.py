import gymnasium as gym
from gymnasium import spaces
import numpy as np


class WraithEnv(gym.Env):
    def __init__(self):
        super().__init__()
        # State: [enemy_x, enemy_y, enemy_z, player_x, player_y, player_z, hp, mp, distance, can_summon, can_tornado]
        self.observation_space = spaces.Box(low=-100, high=100, shape=(11,), dtype=np.float32)
        # Actions: 0=summon, 1=tornado, 2=attack, 3=retreat, 4=chase
        self.action_space = spaces.Discrete(5)
        self.reset()

    def reset(self, seed=None, options=None):
        self.state = np.zeros(11, dtype=np.float32)
        self.state[6] = 100  # hp
        self.state[7] = 100  # mp
        return self.state, {}

    def step(self, action):
        reward = 0
        done = False
        # Dummy logic: reward for attacking if close, penalize for wrong skill usage
        distance = self.state[8]
        if action == 2 and distance < 5:
            reward = 1
        elif action == 0 and self.state[9]:
            reward = 0.5
        elif action == 1 and self.state[10]:
            reward = 0.5
        else:
            reward = -0.1
        # Dummy episode end
        done = np.random.rand() < 0.01
        return self.state, reward, done, False, {}

    def render(self):
        pass
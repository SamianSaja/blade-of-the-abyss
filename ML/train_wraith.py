from stable_baselines3 import PPO
from gym_wraith import WraithEnv

env = WraithEnv()
model = PPO("MlpPolicy", env, verbose=1)
model.learn(total_timesteps=10000)
model.save("ppo_wraith")
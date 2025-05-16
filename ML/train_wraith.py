from stable_baselines3 import PPO
from gym_wraith import WraithEnv  # Make sure gym_wraith.py is in the same folder or PYTHONPATH

def main():
    env = WraithEnv()

    # Optional: set seed for reproducibility
    env.reset(seed=42)

    model = PPO(
        "MlpPolicy",
        env,
        verbose=1,
        learning_rate=3e-4,
        batch_size=64,
        n_steps=2048,
        ent_coef=0.01,
        gamma=0.99,
        gae_lambda=0.95,
        clip_range=0.2,
        max_grad_norm=0.5,
    )

    # Increase total_timesteps for better training (e.g., 1 million)
    model.learn(total_timesteps=1_000_000)

    model.save("ppo_wraith_v3")

if __name__ == "__main__":
    main()
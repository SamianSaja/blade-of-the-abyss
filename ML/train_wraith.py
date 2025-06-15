# train_wraith.py
from stable_baselines3 import PPO
from gym_wraith import WraithEnv

def main():
    env = WraithEnv()
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

    model.learn(total_timesteps=100_000)
    model.save("ppo_wraith_adaptive_v7")
    print(f"Total Episodes Completed: {env.episode_count}")

if __name__ == "__main__":
    main()
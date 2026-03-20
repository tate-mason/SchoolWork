"""
Neural Network Estimation (NNE) of the Migration Model

Applies the NNE approach from Bhatt, Misra, and Qi (2023) to the
migration model in migration_model.py.

Idea:
  1. Draw N_TRAIN parameter vectors theta from a prior
  2. Simulate the model for each theta, compute summary moments
  3. Train a neural network: f(moments) -> theta
  4. Evaluate on a test point (true theta known from simulation)

NNE separates the expensive simulation step (offline, done once)
from estimation (online, a single forward pass through the NN).
"""

import numpy as np
from sklearn.neural_network import MLPRegressor
from sklearn.preprocessing import StandardScaler

# Import the model and pre-built environment
from migration_model import env, simulate_model_moments


# =============================
# 1. Define Moments Vector
# =============================

def moments_vector(moms):
    """
    Flatten simulation output into a fixed-length feature vector.

    Uses:
      - overall move rates for two age groups (scalar x2)
      - move probabilities for the first 5 two-year age bands (scalar x5)
    """
    return np.array([
        moms['p_move_40_50'],
        moms['p_move_65p'],
        *moms['p_move_pairs'][:5],
    ])


# =============================
# 2. Generate Training Data
# =============================

N_TRAIN  = 200     # parameter draws  (increase for better NNE accuracy)
N_AGENTS = 10_000  # agents per simulation (speed/accuracy tradeoff)

rng = np.random.default_rng(42)

# Draw parameters from a uniform prior over plausible ranges
gamma_W_draws = rng.uniform(0.5, 10.0, N_TRAIN)
gamma_R_draws = rng.uniform(0.5, 10.0, N_TRAIN)
alpha_W_draws = rng.uniform(-2.0,  2.0, N_TRAIN)
alpha_R_draws = rng.uniform(-2.0,  2.0, N_TRAIN)

thetas = np.column_stack([gamma_W_draws, gamma_R_draws,
                           alpha_W_draws, alpha_R_draws])

print(f"Generating {N_TRAIN} training simulations ({N_AGENTS} agents each)...")
X_list = []
for i, theta in enumerate(thetas):
    moms = simulate_model_moments(tuple(theta), env, n_agents=N_AGENTS, rng=rng)
    X_list.append(moments_vector(moms))
    if (i + 1) % 50 == 0:
        print(f"  {i + 1}/{N_TRAIN} done")

X_train = np.array(X_list)   # shape (N_TRAIN, n_moments)
y_train = thetas              # shape (N_TRAIN, 4)

print("Training data ready.")


# =============================
# 3. Train the NNE
# =============================

# Standardize inputs and outputs so the NN trains more stably
scaler_X = StandardScaler()
scaler_y = StandardScaler()

X_scaled = scaler_X.fit_transform(X_train)
y_scaled = scaler_y.fit_transform(y_train)

nne = MLPRegressor(
    hidden_layer_sizes=(64, 64),
    activation='relu',
    max_iter=1000,
    random_state=42,
    verbose=False,
)
nne.fit(X_scaled, y_scaled)

print(f"NNE training complete. Final loss: {nne.loss_:.6f}")


# =============================
# 4. Evaluate on a Test Point
# =============================

# Use the same test parameters as in the Julia example
theta_true = (5.5, 5.0, 0.5, 0.5)

print("\nSimulating test data (100,000 agents)...")
moms_test = simulate_model_moments(theta_true, env, n_agents=100_000, rng=rng)
m_test    = moments_vector(moms_test).reshape(1, -1)

# Predict with NNE
m_scaled        = scaler_X.transform(m_test)
theta_hat_scaled = nne.predict(m_scaled)
theta_hat        = scaler_y.inverse_transform(theta_hat_scaled)[0]

param_names = ['gamma_W', 'gamma_R', 'alpha_W', 'alpha_R']
print("\nNNE Estimation Results:")
print(f"{'Parameter':<12} {'True':>8} {'NNE Est.':>10} {'Error':>8}")
print("-" * 42)
for name, tv, ev in zip(param_names, theta_true, theta_hat):
    print(f"{name:<12} {tv:>8.3f} {ev:>10.3f} {ev - tv:>+8.3f}")

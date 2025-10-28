import numpy as np
import pandas as pd
import statsmodels.api as sm
from statsmodels.formula.api import ols
from statsmodels.formula.api import logit
import seaborn as sns
import matplotlib.pyplot as plt

"""
This module creates functions to estimate migration behaviors of individuals before and after retirement. We will use simulated data in an attempt to match
the observed data on migration patterns, particularly focusing on the age group 50-80.
For retirees: we estimate the probability of moving after retirement using logistic regression. Their primary motivator is amenities in a state z.
For workers: we estimate the probability of moving using logistic regression. Their primary motivator is job opportunities in a state z.

The module also includes functions to visualize the results of these estimations. Data is from IPUMS, and the analysis focuses on individuals aged 50-80.
"""

"""
Creating simulated data, allowing us to see how our model can match up with observed migration patterns.
"""
def create_simulated_data(n=1000):
    np.random.seed(219)
    data = pd.DataFrame({
        'age': np.random.randint(50, 81, size = n),
        'retired': np.random.binomial(1, 0.5, size = n),
        'amenities': np.random.uniform(0, 10, size = n),
        'job_opportunities': np.random.uniform(0, 10, size = n),
        # state-dependent income
        'income': np.random.normal(50000, 15000, size = n),
        # Choice of state from 1 to 50
        'state': np.random.randint(1, 51, size = n),
        'prob_retire': np.random.uniform(0, 1, size = n),
        'prob_die': np.random.uniform(0, 1, size = n),
        'delta': np.random.uniform(0, 1, size = n), # information percision when choosing states
    })


def estimate_retirement_migration(data):
    """
    Estimate the probability of moving after retirement using logistic regression.
    
    Parameters:
    data (DataFrame): A pandas DataFrame containing the relevant data.
    
    Returns:
    model: The fitted logistic regression model.
    """
    # Filter data for retirees aged 50-80
    retirees = data[(data['age'] >= 50) & (data['age'] <= 80) & (data['retired'] == 1)]
    
    # Define the logistic regression formula
    formula = 'moved ~ amenities + income + health_status + age'

    # Fit the logistic regression model
    model = logit(formula, data=retirees).fit()
    return model

def estimate_worker_migration(data):
    """
    Estimate the probability of moving for workers using logistic regression.
    
    Parameters:
    data (DataFrame): A pandas DataFrame containing the relevant data.
    
    Returns:
    model: The fitted logistic regression model.
    """
    # Filter data for workers aged 50-80
    workers = data[(data['age'] >= 50) & (data['age'] <= 80) & (data['retired'] == 0)]
    
    # Define the logistic regression formula
    formula = 'moved ~ job_opportunities + income + family_ties + age'

    # Fit the logistic regression model
    model = logit(formula, data=workers).fit()
    return model

def plot_migration_probabilities(model, title):
    """
    Plot the predicted probabilities of moving based on the fitted model.
    
    Parameters:
    model: The fitted logistic regression model.
    title (str): The title for the plot.
    """
    # Create a range of values for the primary predictor
    if 'amenities' in model.model.exog_names:
        x = np.linspace(0, 10, 100)
        df = pd.DataFrame({'amenities': x, 'income': np.mean(model.model.exog[:, model.model.exog_names.index('income')]),
                           'health_status': np.mean(model.model.exog[:, model.model.exog_names.index('health_status')]),
                           'age': np.mean(model.model.exog[:, model.model.exog_names.index('age')])})
    else:
        x = np.linspace(0, 10, 100)
        df = pd.DataFrame({'job_opportunities': x, 'income': np.mean(model.model.exog[:, model.model.exog_names.index('income')]),
                           'family_ties': np.mean(model.model.exog[:, model.model.exog_names.index('family_ties')]),
                           'age': np.mean(model.model.exog[:, model.model.exog_names.index('age')])})

    # Predict probabilities
    df['predicted_prob'] = model.predict(df)

    # Plotting
    plt.figure(figsize=(10, 6))
    sns.lineplot(x=x, y=df['predicted_prob'])
    plt.title(title)
    plt.xlabel('Primary Predictor')
    plt.ylabel('Predicted Probability of Moving')
    plt.ylim(0, 1)
    plt.grid()
    plt.show()

"""
Value functions for retirees and workers to estimate utilities based on state characteristics. 
For workers: utility depends on wage in state z, housing costs in state z, and consumption
    they supply labor inelastically and earn wage w(z). When they move, they pay moving costs based on housing prices in state z'.
    U_w(c, m(z);t) = (c^(1-sigma))/(1-sigma) - gamma*{z' =/= z} where gamma is a disutility from moving.
    bc: c = w(z) - housing_costs(z) - tax(z) 
    V^w(z) = max{V_w^M(z'; t), V_w^S(z; t)}
    V_w^M = max_{z', c){U(c, m(z); t) + (1-prob_retire)*beta*E[V^w(z'); t+1|delta] + prob_retire*beta*E[V^r(z'); t+1|delta]}
    V_w^S = max_{c}{U(c, m(z); t) + (1-prob_retire)*beta*V^w(z); t+1 + prob_retire*beta*V^r(z); t+1}

    where V^w(z) is the value for workers in state z. They choose to move (M) or stay (S) based on maximizing their expected utility.
    If they move, they consider the expected value of being in a new state z' next period, which is informed by their knowledge, delta, weighted by the probability of retiring.

For retirees: utility depends on amenities in state z, healthcare costs in state z, and consumption
    they do not earn labor income but have retirement income and pay healthcare costs that vary by state.
    U_r(c, m(z);t) = (c^(1-sigma))/(1-sigma) - gamma*{z' =/= z}
    bc: c = retirement_income - healthcare_costs(z)
    V^r(z) = max{V_r^M(z'; t), V_r^S(z; t)}
    V_r^M = max_{z', c){U(c, m(z); t) + beta*E[V^r(z'); t+1|delta]}
    V_r^S = max_{c}{U(c, m(z); t) + beta*V^r(z); t+1}

    V^r(z) is the value for retirees in state z. They choose to move (M) or stay (S) based on maximizing their expected utility. The rest is the same as above
"""

def value_function_worker(wage, housing_costs, state, tax, prob_retire, beta, delta, V_w_next, V_r_next, gamma=0.1, sigma=2):
    """
    Calculate the value function for workers.
    """
    def U(c, moved):
        return (c**(1-sigma)) / (1-sigma) - gamma * moved

    # Staying
    c_stay = wage - housing_costs - tax
    V_w_S = U(c_stay, 0) + (1 - prob_retire) * beta * V_w_next[state] + prob_retire * beta * V_r_next[state]

    # Moving
    V_w_M = -np.inf
    for z_prime in range(len(V_w_next)):
        c_move = wage - housing_costs - tax  # Simplified; in practice, would depend on new state z'
        V_w_M_candidate = U(c_move, 1) + (1 - prob_retire) * beta * V_w_next[z_prime] + prob_retire * beta * V_r_next[z_prime]
        if V_w_M_candidate > V_w_M:
            V_w_M = V_w_M_candidate

    return max(V_w_S, V_w_M)
def value_function_retiree(retirement_income, healthcare_costs, state, beta, delta, V_r_next, gamma=0.1, sigma=2):
    """
    Calculate the value function for retirees.
    """
    def U(c, moved):
        return (c**(1-sigma)) / (1-sigma) - gamma * moved

    # Staying
    c_stay = retirement_income - healthcare_costs
    V_r_S = U(c_stay, 0) + beta * V_r_next[state]

    # Moving
    V_r_M = -np.inf
    for z_prime in range(len(V_r_next)):
        c_move = retirement_income - healthcare_costs  # Simplified; in practice, would depend on new state z'
        V_r_M_candidate = U(c_move, 1) + beta * V_r_next[z_prime]
        if V_r_M_candidate > V_r_M:
            V_r_M = V_r_M_candidate

    return max(V_r_S, V_r_M)
# Results
# Simulate data
data = create_simulated_data(1000)
# Estimate models
retiree_model = estimate_retirement_migration(data)
worker_model = estimate_worker_migration(data)
# Plot results
plot_migration_probabilities(retiree_model, 'Predicted Probability of Moving for Retireees')
plot_migration_probabilities(worker_model, 'Predicted Probability of Moving for Workers')



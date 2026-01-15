import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import statsmodels.api as sm
import time
import os

"""
    This module provides utility functions, probability functions, and data simulation

    Variables used:
      - β: coefficient on consumer preferences for product characteristics
      - xbar_t: average product characteristics across time
      - γ: coefficient on average product characteristics
      - σ: coefficient on min(x - xt) --> distance from any similar product seen before
      - μ: random shock to offered products
      - J: number of products in choice set
      - T: number of time periods
      - N: number of consumers
      - Χ: total catalog of products
    Functions:
"""

class NetflixUser:
    def __init__(self, β, γ, σ, μ, J, T, N, Χ):
        self.β = β
        self.γ = γ
        self.σ = σ
        self.μ = μ
        self.J = J
        self.T = T
        self.N = N
        self.Χ = Χ

    def simulate_choices(self):
        """
        Users choose if they will view a movie each period based on product characteristics and preferences.
        """
        choices = []
        for t in range(self.T):
            for n in range(self.N):
                utilities = []
                for j in range(self.J):
                    x_t = self.Χ[np.random.randint(0, len(self.Χ))]
                    distance = min([abs(x_t - x_prev) for x_prev in choices]) if choices else 0
                    utility = (self.β * x_t) + σ * distance + self.μ * np.random.randn()
                    utilities.append(utility)
                chosen_product = np.argmax(utilities)
                choices.append((n, t, chosen_product))
        return choices

    def plot_choice_distribution(self, choices):
        """
        Plots the distribution of choices made by users over time.
        """
        choice_counts = pd.Series([choice[2] for choice in choices]).value_counts()
        choice_counts.sort_index().plot(kind='bar')
        plt.xlabel('Product')
        plt.ylabel('Number of Choices')
        plt.title('Distribution of User Choices Over Time')
        plt.show()

    def estimate_parameters(self, choices):
        """
        Estimates the parameters of the user choice model using logistic regression.
        """
        data = []
        for choice in choices:
            n, t, j = choice
            x_t = self.Χ[j]
            data.append([n, t, x_t])
        df = pd.DataFrame(data, columns=['User', 'Time', 'Product_Characteristic'])
        df['Chosen'] = 1

        X = sm.add_constant(df[['Product_Characteristic']])
        y = df['Chosen']
        model = sm.Logit(y, X)
        result = model.fit()
        return result.summary()
# Example usage
if __name__ == "__main__":
    # Define parameters
    β = 0.5
    γ = 0.3
    σ = 0.2
    μ = 1.0
    J = 10  # Number of products
    T = 5   # Number of time periods
    N = 100 # Number of users
    Χ = np.random.rand(50) * 10  # Catalog of products with random characteristics

    # Create NetflixUser instance
    user_model = NetflixUser(β, γ, σ, μ, J, T, N, Χ)

    # Simulate choices
    choices = user_model.simulate_choices()

    # Plot choice distribution
    user_model.plot_choice_distribution(choices)

    # Estimate parameters
    summary = user_model.estimate_parameters(choices)
    print(summary)




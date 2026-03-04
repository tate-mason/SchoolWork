import kagglehub
import pandas as pd

path = kagglehub.dataset_download("mayziehunter/wnba-season-standings-1997-2023")

print("Dataset downloaded to:", path)

df = pd.read_csv(path + "/wnba-season-standings-1997-2023")

print(df.head())

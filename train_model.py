import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score
from sklearn.model_selection import train_test_split
import joblib
import json

# --- Data Loading ---
print("Loading dataset...")
df = pd.read_excel('cleaned_datasets.xlsx')
print(f"Dataset loaded: {df.shape[0]} rows, {df.shape[1]} columns")

# Clean Place of Accident column - remove NaN and empty values
print("\nCleaning data...")
original_count = len(df)
df = df.dropna(subset=['Place of Accident'])  # Remove rows with NaN in Place of Accident
df = df[df['Place of Accident'].astype(str).str.strip() != '']  # Remove empty strings
print(f"Removed {original_count - len(df)} rows with missing Place of Accident")
print(f"Remaining rows: {len(df)}")

# Standardize municipality names to avoid duplicates
print("\nStandardizing municipality names...")
municipality_mapping = {
    # Cities
    'alaminos c': 'Alaminos City',
    'alaminos city': 'Alaminos City',
    'dagupan c': 'Dagupan City',
    'dagupan city': 'Dagupan City',
    'san carlos c': 'San Carlos City',
    'san carlos city': 'San Carlos City',
    'urdaneta c': 'Urdaneta City',
    'urdaneta city': 'Urdaneta City',
    'urdaneta': 'Urdaneta City',

    # Municipalities with variations
    'mangaldan m': 'Mangaldan',
    'mapandan m': 'Mapandan',
    'san fabian m': 'San Fabian',
    'sta. barbara': 'Santa Barbara',
    'santo tomas': 'Santo Tomas',
    'villasi': 'Villasis',  # Standardize to Villasis
    'villasis': 'Villasis',

    # Standard municipalities (keep as-is but capitalize properly)
}

# Apply mapping and clean up station names
df['Station'] = df['Station'].str.strip().str.lower()
df['Station'] = df['Station'].replace(municipality_mapping)

# For unmapped stations, just do title case
df.loc[~df['Station'].isin(municipality_mapping.values()), 'Station'] = \
    df.loc[~df['Station'].isin(municipality_mapping.values()), 'Station'].str.title()

print(f"Unique municipalities after standardization: {df['Station'].nunique()}")
print(f"Municipalities: {sorted(df['Station'].unique())}")

# --- Feature Engineering ---
print("\nPerforming feature engineering...")
df['Date Committed'] = pd.to_datetime(df['Date Committed'])
df['month'] = df['Date Committed'].dt.month
df['day_of_week'] = df['Date Committed'].dt.dayofweek
df['Time Committed'] = pd.to_datetime(df['Time Committed'], format='%H:%M:%S').dt.time
df['hour'] = df['Time Committed'].apply(lambda x: x.hour)

# Create unique location identifier: "Barangay, Municipality"
# This prevents mixing barangays with same name in different municipalities
df['location_key'] = df['Place of Accident'].str.strip() + ', ' + df['Station'].str.strip()

# Create 'accident_prone_area' target variable using location_key
accident_counts = df['location_key'].value_counts()
percentile_75 = accident_counts.quantile(0.75)
accident_prone_places = accident_counts[accident_counts > percentile_75].index
df['accident_prone_area'] = df['location_key'].isin(accident_prone_places).astype(int)

print(f"Accident-prone areas identified: {len(accident_prone_places)}")
print(f"Accident-prone samples: {df['accident_prone_area'].sum()}")
print(f"Safe samples: {(df['accident_prone_area'] == 0).sum()}")

# Create detailed statistics per location (barangay + municipality)
place_statistics = {}
for location_key in df['location_key'].unique():
    # Skip NaN values
    if pd.isna(location_key):
        continue

    # Extract barangay and station from location_key
    parts = location_key.split(', ')
    if len(parts) != 2:
        continue

    barangay, station = parts
    location_data = df[df['location_key'] == location_key]

    # Use composite key: "barangay, station" to keep them separate
    key = f"{barangay.lower().strip()}, {station.lower().strip()}"

    place_statistics[key] = {
        'barangay': barangay.strip(),
        'station': station.strip(),
        'total_accidents': len(location_data),
        'is_accident_prone': location_key in accident_prone_places,
        'fatal_accidents': len(location_data[location_data['Severity of Accident (Fatal, Non Fatal, Unharmed, Injured, Etc)'].str.contains('Fatal', na=False, case=False)]),
        'most_common_offense': location_data['Offense'].mode()[0] if not location_data['Offense'].mode().empty else 'Unknown'
    }

# Save the list of accident-prone places with statistics
accident_prone_dict = {
    'places': accident_prone_places.tolist(),
    'threshold': int(percentile_75),
    'total_places': len(df['Place of Accident'].unique()),
    'statistics': place_statistics
}

with open('accident_prone_places.json', 'w') as f:
    json.dump(accident_prone_dict, f, indent=2)

print("\nAccident-prone places saved to 'accident_prone_places.json'")

# --- Data Preprocessing ---
categorical_cols = [
    'Station',
    'Place of Accident',
    'Offense',
    'Vehicles involved',
    "Driver's Behavior (Under Influence of Liqour, Drugs, Etc)",
    'Severity of Accident (Fatal, Non Fatal, Unharmed, Injured, Etc)',
    'Weather Condition',
    'Frequent Location of Accident'
]

print("\nPreprocessing categorical features...")
for col in categorical_cols:
    if df[col].isnull().any():
        df[col] = df[col].fillna(df[col].mode()[0])

df = pd.get_dummies(df, columns=categorical_cols, drop_first=True)
df = df.drop(columns=['Date Committed', 'Time Committed'])

# --- Data Splitting ---
X = df.drop('accident_prone_area', axis=1)
y = df['accident_prone_area']

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Sanitize column names
X_train.columns = X_train.columns.str.replace('[^A-Za-z0-9_]+', '_', regex=True)
X_test.columns = X_test.columns.str.replace('[^A-Za-z0-9_]+', '_', regex=True)

# Check for non-numeric columns and convert
print("\nChecking data types...")
non_numeric_cols = X_train.select_dtypes(include=['object']).columns.tolist()
if non_numeric_cols:
    print(f"Warning: Found non-numeric columns: {non_numeric_cols}")
    print("Converting to numeric or dropping...")
    for col in non_numeric_cols:
        X_train[col] = pd.to_numeric(X_train[col], errors='coerce')
        X_test[col] = pd.to_numeric(X_test[col], errors='coerce')

    # Fill any NaN values created during conversion
    X_train = X_train.fillna(0)
    X_test = X_test.fillna(0)

# Save feature names for later use
feature_names = X_train.columns.tolist()
with open('feature_names.json', 'w') as f:
    json.dump(feature_names, f, indent=2)

print(f"\nConverting data to numpy arrays...")
print(f"X_train shape: {X_train.shape}, dtype: {X_train.dtypes.unique()}")
X_train_np = X_train.values.astype(float)
X_test_np = X_test.values.astype(float)

# --- Model Training ---
print("\nTraining Logistic Regression model...")
lr_model = LogisticRegression(random_state=42, solver='liblinear', max_iter=1000)
lr_model.fit(X_train_np, y_train)

print("Model training completed!")

# --- Model Evaluation ---
y_pred_lr = lr_model.predict(X_test_np)
y_pred_proba = lr_model.predict_proba(X_test_np)

print("\n" + "="*60)
print("LOGISTIC REGRESSION MODEL EVALUATION")
print("="*60)
print(f"\nAccuracy: {accuracy_score(y_test, y_pred_lr):.4f}")
print("\nClassification Report:")
print(classification_report(y_test, y_pred_lr))
print("\nConfusion Matrix:")
print(confusion_matrix(y_test, y_pred_lr))

# --- Save Model ---
print("\nSaving model...")
joblib.dump(lr_model, 'accident_prediction_model.pkl')
print("Model saved as 'accident_prediction_model.pkl'")

# Create model metadata
model_metadata = {
    'model_type': 'LogisticRegression',
    'accuracy': float(accuracy_score(y_test, y_pred_lr)),
    'training_samples': len(X_train),
    'test_samples': len(X_test),
    'feature_count': len(feature_names),
    'accident_prone_threshold': int(percentile_75),
    'total_accident_prone_areas': len(accident_prone_places)
}

with open('model_metadata.json', 'w') as f:
    json.dump(model_metadata, f, indent=2)

print("\n" + "="*60)
print("MODEL TRAINING COMPLETE!")
print("="*60)
print("\nGenerated files:")
print("1. accident_prediction_model.pkl")
print("2. accident_prone_places.json")
print("3. feature_names.json")
print("4. model_metadata.json")
print(f"\nTotal accident-prone barangays: {len(accident_prone_places)}")
print(f"Sample accident-prone areas: {', '.join(accident_prone_places[:10].tolist())}")
"""
Train a small TensorFlow model that recommends which game a patient should
play next, then export it as TensorFlow Lite for on-device use in Melo.

FEATURE VECTOR (15 values) — this exact order and meaning must match the
Dart feature extraction in recommendation_service.dart:

  Per game (4 games x 3 features = 12 values), in this fixed order:
    [memory_matching_ner, daily_routine_recall_ner,
     attention_focus_ner, trip_itinerary_recall_ner]

    For each game:
      0: recent_accuracy      (0.0-1.0, avg of last 3 sessions; 0.6 default
                                if the patient has never played this game)
      1: staleness            (0.0-1.0, days since last played / 14, capped
                                at 1.0; 1.0 if never played)
      2: difficulty_encoded   (0.0=easy, 0.5=medium, 1.0=hard; 0.5 default)

  Global features (3 values):
    12: overall_trend         (-1.0 to 1.0, slope of accuracy over last 5
                                sessions across all games; 0.0 if <2 sessions)
    13: total_sessions_norm   (0.0-1.0, total session count / 20, capped)
    14: avg_duration_norm     (0.0-1.0, avg session duration seconds / 180,
                                capped)

OUTPUT: softmax over 4 classes, one per game (same order as above).
"""

import numpy as np
import tensorflow as tf

np.random.seed(42)
tf.random.set_seed(42)

GAMES = [
    "memory_matching_ner",
    "daily_routine_recall_ner",
    "attention_focus_ner",
    "trip_itinerary_recall_ner",
]
NUM_GAMES = len(GAMES)
NUM_FEATURES = NUM_GAMES * 3 + 3


def generate_synthetic_dataset(n_samples: int):
    """Generate synthetic patient feature vectors and label each one using
    a smoothed, generalized version of the domain logic already used by
    DifficultyEngine and the dashboard: recommend the game that is weakest
    (low accuracy) AND/OR stalest (not played recently), since that's the
    game most in need of reinforcement. This distills existing rule-based
    intuition into training data — see the accompanying guide for why."""

    X = np.zeros((n_samples, NUM_FEATURES), dtype=np.float32)
    y = np.zeros((n_samples,), dtype=np.int64)

    for i in range(n_samples):
        game_scores = np.zeros(NUM_GAMES)

        for g in range(NUM_GAMES):
            # Randomly decide if this game has been played at all yet
            has_played = np.random.random() > 0.15

            if has_played:
                recent_accuracy = np.clip(np.random.normal(0.65, 0.2), 0.0, 1.0)
                staleness = np.clip(np.random.exponential(0.3), 0.0, 1.0)
                difficulty = np.random.choice([0.0, 0.5, 1.0])
            else:
                recent_accuracy = 0.6  # neutral default
                staleness = 1.0        # never played = maximally stale
                difficulty = 0.5

            base = i * NUM_GAMES * 3 + g * 3
            # (placeholder, filled properly below with per-game blocks)
            X[i, g * 3 + 0] = recent_accuracy
            X[i, g * 3 + 1] = staleness
            X[i, g * 3 + 2] = difficulty

            # Need-for-reinforcement score: low accuracy + high staleness
            # both push a game up the recommendation list.
            game_scores[g] = (1.0 - recent_accuracy) * 0.6 + staleness * 0.4

        # Global features
        overall_trend = np.clip(np.random.normal(0.0, 0.4), -1.0, 1.0)
        total_sessions_norm = np.clip(np.random.exponential(0.3), 0.0, 1.0)
        avg_duration_norm = np.clip(np.random.normal(0.5, 0.2), 0.0, 1.0)

        X[i, NUM_GAMES * 3 + 0] = overall_trend
        X[i, NUM_GAMES * 3 + 1] = total_sessions_norm
        X[i, NUM_GAMES * 3 + 2] = avg_duration_norm

        # If the patient is new (very few sessions), don't let noise decide —
        # default toward memory_matching_ner as a safe first recommendation.
        if total_sessions_norm < 0.05:
            y[i] = 0
        else:
            # Small random noise so the model learns a soft decision boundary
            # rather than memorizing an exact threshold.
            noisy_scores = game_scores + np.random.normal(0, 0.05, NUM_GAMES)
            y[i] = int(np.argmax(noisy_scores))

    return X, y


def build_model():
    model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=(NUM_FEATURES,)),
        tf.keras.layers.Dense(16, activation="relu"),
        tf.keras.layers.Dense(8, activation="relu"),
        tf.keras.layers.Dense(NUM_GAMES, activation="softmax"),
    ])
    model.compile(
        optimizer="adam",
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    return model


def main():
    print("Generating synthetic training data...")
    X_train, y_train = generate_synthetic_dataset(8000)
    X_val, y_val = generate_synthetic_dataset(1500)

    print(f"Feature vector size: {NUM_FEATURES}")
    print(f"Class distribution (train): {np.bincount(y_train)}")

    model = build_model()
    model.summary()

    print("\nTraining...")
    model.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=30,
        batch_size=32,
        verbose=2,
    )

    val_loss, val_acc = model.evaluate(X_val, y_val, verbose=0)
    print(f"\nFinal validation accuracy: {val_acc:.3f}")

    # Save Keras model
    model.save("recommendation_model.keras")
    print("Saved recommendation_model.keras")

    # Convert to TensorFlow Lite with default quantization
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()

    with open("recommendation_model.tflite", "wb") as f:
        f.write(tflite_model)

    import os
    size_kb = os.path.getsize("recommendation_model.tflite") / 1024
    print(f"Saved recommendation_model.tflite ({size_kb:.1f} KB)")


if __name__ == "__main__":
    main()

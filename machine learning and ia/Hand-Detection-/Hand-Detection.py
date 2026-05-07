import cv2
import mediapipe as mp
from flask import Flask, render_template, jsonify
import threading

app = Flask(__name__)

mp_hands = mp.solutions.hands
hands = mp_hands.Hands(max_num_hands=1, min_detection_confidence=0.7)
mp_draw = mp.solutions.drawing_utils

cap = cv2.VideoCapture(0)

current_action = ""

def count_fingers(hand_landmarks):
    tips_ids = [4, 8, 12, 16, 20]
    fingers = []

    if hand_landmarks.landmark[tips_ids[0]].x < hand_landmarks.landmark[tips_ids[0] - 1].x:
        fingers.append(1)
    else:
        fingers.append(0)

    for id in range(1, 5):
        if hand_landmarks.landmark[tips_ids[id]].y < hand_landmarks.landmark[tips_ids[id] - 2].y:
            fingers.append(1)
        else:
            fingers.append(0)

    return fingers.count(1)

def capture_gesture():
    global current_action
    while True:
        ret, frame = cap.read()
        frame = cv2.flip(frame, 1)  
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        result = hands.process(rgb_frame)

        if result.multi_hand_landmarks:
            for hand_landmarks in result.multi_hand_landmarks:
                mp_draw.draw_landmarks(frame, hand_landmarks, mp_hands.HAND_CONNECTIONS)
                fingers_up = count_fingers(hand_landmarks)

                if fingers_up == 5:
                    current_action = "Yes"
                elif fingers_up == 2:
                    current_action = "Next"
                elif fingers_up == 1:
                    current_action = "Back"
                else:
                    current_action = "..."

        cv2.imshow("Hand Gesture Control", frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/gesture')
def get_gesture():
    return jsonify({'action': current_action})

def run_flask():
    app.run(debug=True, use_reloader=False)

flask_thread = threading.Thread(target=run_flask)
flask_thread.start()

# Start the hand gesture capture
capture_gesture()

cap.release()
cv2.destroyAllWindows()

import os
import io
import time
import json
import base64
import wave
import uuid
import datetime
from flask import Flask, request, jsonify, send_file, send_from_directory
from flask_cors import CORS

try:
    import lameenc
    HAS_LAMEENC = True
except ImportError:
    HAS_LAMEENC = False

app = Flask(__name__)
# Enable CORS for all routes so Flutter web, mobile, and desktop can connect seamlessly
CORS(app, resources={r"/*": {"origins": "*"}})

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
STORAGE_DIR = os.path.join(BASE_DIR, "storage")
AUDIO_DIR = os.path.join(STORAGE_DIR, "audio")
JSON_DIR = os.path.join(STORAGE_DIR, "json")

os.makedirs(AUDIO_DIR, exist_ok=True)
os.makedirs(JSON_DIR, exist_ok=True)


def convert_wav_to_mp3(wav_bytes: bytes) -> bytes:
    """Converts WAV audio bytes to MP3 bytes using lameenc."""
    if not HAS_LAMEENC:
        return wav_bytes

    try:
        wav_io = io.BytesIO(wav_bytes)
        with wave.open(wav_io, 'rb') as wav_file:
            channels = wav_file.getnchannels()
            sample_rate = wav_file.getframerate()
            sample_width = wav_file.getsampwidth()
            frames = wav_file.readframes(wav_file.getnframes())

        # lameenc expects 16-bit PCM
        if sample_width != 2:
            # If not 16-bit, return original or pass through
            pass

        encoder = lameenc.Encoder()
        encoder.set_bit_rate(128)
        encoder.set_in_sample_rate(sample_rate)
        encoder.set_channels(channels)
        encoder.set_quality(2)  # High quality

        mp3_data = encoder.encode(frames) + encoder.flush()
        return bytes(mp3_data)
    except Exception as e:
        print(f"Warning: WAV to MP3 conversion failed ({e}), saving original data.")
        return wav_bytes


@app.route("/", methods=["GET"])
def index():
    return jsonify({
        "status": "online",
        "service": "Cyber-Physical Healthcare System - Audio Backend",
        "endpoints": {
            "upload_voice_note": "POST /api/voice-notes/upload",
            "list_voice_notes": "GET /api/voice-notes",
            "get_voice_note_metadata": "GET /api/voice-notes/<id>",
            "get_mp3_audio": "GET /api/voice-notes/<id>/audio",
            "get_json_file": "GET /api/voice-notes/<id>/json",
            "health": "GET /api/health"
        }
    })


@app.route("/api/health", methods=["GET"])
def health():
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "storage": {
            "audio_dir": AUDIO_DIR,
            "json_dir": JSON_DIR,
            "notes_count": len([f for f in os.listdir(JSON_DIR) if f.endswith('.json')])
        }
    })


@app.route("/api/voice-notes/upload", methods=["POST"])
def upload_voice_note():
    """
    Accepts:
    1. multipart/form-data with file field 'audio' or 'file', and optional form fields
       'id', 'duration_seconds', 'recorded_at', 'notes', 'patient_id'.
    2. application/json with 'audio_base64' and metadata fields.
    """
    try:
        note_id = None
        duration_seconds = 0
        recorded_at = datetime.datetime.now(datetime.timezone.utc).isoformat()
        notes = ""
        patient_id = "default_patient"
        audio_bytes = b""
        original_filename = "recording.wav"

        if request.is_json:
            data = request.get_json() or {}
            note_id = data.get("id")
            duration_seconds = int(data.get("duration_seconds", 0))
            recorded_at = data.get("recorded_at", recorded_at)
            notes = data.get("notes", "")
            patient_id = data.get("patient_id", patient_id)
            original_filename = data.get("filename", "recording.wav")
            b64_str = data.get("audio_base64", "")
            if b64_str:
                audio_bytes = base64.b64decode(b64_str)
        else:
            note_id = request.form.get("id")
            duration_seconds = int(request.form.get("duration_seconds", 0))
            recorded_at = request.form.get("recorded_at", recorded_at)
            notes = request.form.get("notes", "")
            patient_id = request.form.get("patient_id", patient_id)

            uploaded_file = request.files.get("audio") or request.files.get("file")
            if uploaded_file:
                original_filename = uploaded_file.filename or "recording.wav"
                audio_bytes = uploaded_file.read()
            elif request.data:
                audio_bytes = request.data

        if not audio_bytes:
            return jsonify({"error": "No audio content provided in request"}), 400

        # Generate a unique note ID if not supplied
        if not note_id or note_id.strip() == "":
            ts = int(time.time() * 1000)
            note_id = f"vn_{ts}"

        # Convert to MP3 if it's WAV or has WAV header (starts with RIFF)
        if audio_bytes.startswith(b"RIFF") or original_filename.lower().endswith(".wav"):
            mp3_bytes = convert_wav_to_mp3(audio_bytes)
        else:
            mp3_bytes = audio_bytes

        # Save MP3 file
        mp3_filename = f"{note_id}.mp3"
        mp3_filepath = os.path.join(AUDIO_DIR, mp3_filename)
        with open(mp3_filepath, "wb") as f:
            f.write(mp3_bytes)

        # Convert audio to Base64 for JSON serialization
        audio_b64 = base64.b64encode(mp3_bytes).decode('utf-8')
        file_size = len(mp3_bytes)

        # Create structured JSON payload
        json_filename = f"{note_id}.json"
        json_filepath = os.path.join(JSON_DIR, json_filename)
        
        note_json_data = {
            "id": note_id,
            "filename": mp3_filename,
            "original_filename": original_filename,
            "mp3_file_path": mp3_filepath,
            "json_file_path": json_filepath,
            "file_size_bytes": file_size,
            "duration_seconds": duration_seconds,
            "recorded_at": recorded_at,
            "uploaded_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            "content_type": "audio/mpeg",
            "audio_url": f"/api/voice-notes/{note_id}/audio",
            "json_url": f"/api/voice-notes/{note_id}/json",
            "patient_id": patient_id,
            "notes": notes,
            "audio_base64": audio_b64
        }

        # Save the JSON file to disk
        with open(json_filepath, "w", encoding="utf-8") as f:
            json.dump(note_json_data, f, indent=2, ensure_ascii=False)

        print(f"[Backend] Successfully saved MP3: {mp3_filepath} ({file_size} bytes)")
        print(f"[Backend] Successfully saved JSON: {json_filepath}")

        # Return response without massive base64 in response headers/body for light client transfer,
        # but include it in the saved json file
        response_data = dict(note_json_data)
        # Keep response light, client has audio_url
        response_data["audio_base64_length"] = len(audio_b64)
        del response_data["audio_base64"]

        return jsonify({
            "success": True,
            "message": "Audio recorded, MP3 saved, and JSON file generated successfully.",
            "voice_note": response_data
        }), 201

    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500


@app.route("/api/voice-notes", methods=["GET"])
def list_voice_notes():
    """Lists all stored voice notes."""
    notes = []
    for filename in sorted(os.listdir(JSON_DIR), reverse=True):
        if filename.endswith(".json"):
            filepath = os.path.join(JSON_DIR, filename)
            try:
                with open(filepath, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    # Don't send huge base64 in list
                    if "audio_base64" in data:
                        del data["audio_base64"]
                    notes.append(data)
            except Exception as e:
                print(f"Error reading {filepath}: {e}")
    return jsonify({"voice_notes": notes, "total": len(notes)})


@app.route("/api/voice-notes/<note_id>", methods=["GET"])
def get_voice_note(note_id):
    """Returns the metadata of a specific voice note."""
    json_filename = f"{note_id}.json"
    json_filepath = os.path.join(JSON_DIR, json_filename)
    if not os.path.exists(json_filepath):
        return jsonify({"error": f"Voice note {note_id} not found"}), 404

    with open(json_filepath, "r", encoding="utf-8") as f:
        data = json.load(f)
    return jsonify(data)


@app.route("/api/voice-notes/<note_id>/audio", methods=["GET"])
def get_voice_note_audio(note_id):
    """Streams or downloads the saved MP3 file."""
    mp3_filename = f"{note_id}.mp3"
    mp3_filepath = os.path.join(AUDIO_DIR, mp3_filename)
    if not os.path.exists(mp3_filepath):
        return jsonify({"error": f"Audio file for {note_id} not found"}), 404

    return send_file(
        mp3_filepath,
        mimetype="audio/mpeg",
        as_attachment=request.args.get("download") == "true",
        download_name=mp3_filename
    )


@app.route("/api/voice-notes/<note_id>/json", methods=["GET"])
def get_voice_note_json_file(note_id):
    """Downloads the saved JSON file."""
    json_filename = f"{note_id}.json"
    json_filepath = os.path.join(JSON_DIR, json_filename)
    if not os.path.exists(json_filepath):
        return jsonify({"error": f"JSON file for {note_id} not found"}), 404

    return send_file(
        json_filepath,
        mimetype="application/json",
        as_attachment=True,
        download_name=json_filename
    )


@app.route("/api/voice-notes/<note_id>", methods=["DELETE"])
def delete_voice_note(note_id):
    """Deletes both MP3 and JSON files for a voice note."""
    mp3_filepath = os.path.join(AUDIO_DIR, f"{note_id}.mp3")
    json_filepath = os.path.join(JSON_DIR, f"{note_id}.json")

    deleted = False
    if os.path.exists(mp3_filepath):
        os.remove(mp3_filepath)
        deleted = True
    if os.path.exists(json_filepath):
        os.remove(json_filepath)
        deleted = True

    if deleted:
        return jsonify({"success": True, "message": f"Voice note {note_id} deleted."})
    return jsonify({"error": f"Voice note {note_id} not found"}), 404


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    print(f"=====================================================")
    print(f" MediRescue Backend Server running on http://127.0.0.1:{port}")
    print(f" Audio MP3 Storage: {AUDIO_DIR}")
    print(f" JSON Storage:      {JSON_DIR}")
    print(f"=====================================================")
    app.run(host="0.0.0.0", port=port, debug=False)

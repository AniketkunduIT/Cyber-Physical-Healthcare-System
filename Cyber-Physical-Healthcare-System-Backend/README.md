# Cyber-Physical Healthcare System — Backend Server

A high-performance REST API backend for the MediRescue Cyber-Physical Healthcare System.

## Features
- **Audio Ingestion & MP3 Conversion**: Accepts audio recordings (WAV/PCM/MP3/M4A) and converts/saves them as high-quality `.mp3` files in `storage/audio/`.
- **JSON File Generation**: Generates and stores structured `.json` files in `storage/json/` containing all metadata, timestamps, file sizes, audio streaming URLs, and full base64 audio representation.
- **RESTful Endpoints**:
  - `POST /api/voice-notes/upload`: Uploads audio, saves MP3, and creates JSON file.
  - `GET /api/voice-notes`: Lists all voice notes with their MP3 & JSON file links.
  - `GET /api/voice-notes/<id>`: Returns metadata of a specific voice note.
  - `GET /api/voice-notes/<id>/audio`: Streams or downloads the `.mp3` file.
  - `GET /api/voice-notes/<id>/json`: Downloads the `.json` representation file.
  - `DELETE /api/voice-notes/<id>`: Deletes both MP3 and JSON files.
  - `GET /api/health`: Health status and storage statistics.

## Requirements & Setup
```bash
pip install -r requirements.txt
python app.py
```
Default server URL: `http://127.0.0.1:5000`

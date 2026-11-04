import urllib.request
import json
import wave
import io
import struct
import math

# Generate 1.5s 440Hz WAV
sample_rate = 44100
duration = 1.5
buf = io.BytesIO()
with wave.open(buf, 'wb') as wf:
    wf.setnchannels(1)
    wf.setsampwidth(2)
    wf.setframerate(sample_rate)
    for i in range(int(sample_rate * duration)):
        val = int(32767 * 0.5 * math.sin(2 * math.pi * 440 * i / sample_rate))
        wf.writeframes(struct.pack('<h', val))

wav_data = buf.getvalue()

boundary = '----WebKitFormBoundaryTest'
body = bytearray()
body.extend(f'--{boundary}\r\nContent-Disposition: form-data; name="duration_seconds"\r\n\r\n2\r\n'.encode('utf-8'))
body.extend(f'--{boundary}\r\nContent-Disposition: form-data; name="notes"\r\n\r\nHeart patient test\r\n'.encode('utf-8'))
body.extend(f'--{boundary}\r\nContent-Disposition: form-data; name="audio"; filename="test_sample.wav"\r\nContent-Type: audio/wav\r\n\r\n'.encode('utf-8'))
body.extend(wav_data)
body.extend(f'\r\n--{boundary}--\r\n'.encode('utf-8'))

req = urllib.request.Request(
    'http://127.0.0.1:5000/api/voice-notes/upload',
    data=bytes(body),
    headers={'Content-Type': f'multipart/form-data; boundary={boundary}'}
)
with urllib.request.urlopen(req) as resp:
    res = resp.read().decode('utf-8')
    print("Response:")
    print(res)

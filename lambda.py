import os
import json
import urllib3
from openai import OpenAI

# Lambda-Caching bei Warm Starts wird verwendet
client = OpenAI()
# Timeouts für die HTTP-Anfragen 
http = urllib3.PoolManager(timeout=urllib3.Timeout(connect=2.0, read=5.0))

def handler(event, context):
    incoming_data = {}
    
    if isinstance(event, dict) and "body" in event:
        raw_body = event.get("body", "{}")
        if event.get("isBase64Encoded", False):
            import base64
            raw_body = base64.b64decode(raw_body).decode("utf-8")
        try:
            incoming_data = json.loads(raw_body) if isinstance(raw_body, str) else raw_body
        except Exception:
            incoming_data = {}
    elif isinstance(event, dict):
        incoming_data = event

    run_id = incoming_data.get("runId")
    app_id = incoming_data.get("appId")
    app_name = incoming_data.get("appName")
    artist_input = incoming_data.get("artistName")
    song_input = incoming_data.get("songTitle")
    submit_url = incoming_data.get("resultSubmitUrl")
    
    base_url = "https://test-0k.onrender.com/lyrics/"
    
    try:
        response = http.request(
            "GET",
            base_url,
            fields={"artist": artist_input, "song": song_input}
        )
        res_json = json.loads(response.data.decode("utf-8"))
        api_data_block = res_json.get("data", {})
        lyrics = api_data_block.get("lyrics", "Kein Songtext gefunden.")
    except Exception as e:
        print(f"Fehler beim Lyrics-Abruf: {str(e)}")
        return "Error fetching lyrics"
        
    try:
        openai_response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "Du bist ein Musikexperte. Analysiere den bereitgestellten Songtext."},
                {"role": "user", "content": f"Künstler: {artist_input}\nTitel: {song_input}\n\nSongtext:\n{lyrics}\n\nSchreibe eine kurze Interpretation mit 3 Sätzen dazu."}
            ],
            max_tokens=250
        )
        
        ai_result = openai_response.choices[0].message.content
        word_count = len(lyrics.split()) if lyrics != 'Kein Songtext gefunden.' else 0

        final_payload = {
            "runId": run_id,
            "appId": app_id,
            "appName": app_name,
            "artists": {
                "singers": [artist_input] if artist_input else ["..."],
                "producers": ["..."]
            },
            "song": {
                "title": song_input if song_input else "...",
                "releaseDate": "...",
                "album": "..."
            },
            "wordCount": word_count,
            "summary": ai_result,
            "comicImageUrl": ""
        }
        
        if submit_url:
            try:
                submit_response = http.request(
                    "POST",
                    submit_url,
                    headers={"Content-Type": "application/json"},
                    body=json.dumps(final_payload, ensure_ascii=False).encode("utf-8")
                )
                print(f"Submit Response Status: {submit_response.status}")
            except Exception as submit_error:
                print(f"Error sending data: {str(submit_error)}")
            
    except Exception as e:
        print(f"Fehler bei OpenAI oder Senden: {str(e)}")

    return "Process finished successfully"
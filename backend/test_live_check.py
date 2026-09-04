import urllib.request
import json

def check_url(url, label):
    print(f"--- TESTING {label} ({url}) ---")
    data = json.dumps({"username": "abbosmath", "password": "abbosmath"}).encode("utf-8")
    headers = {
        "Content-Type": "application/json",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    }
    req = urllib.request.Request(url, data=data, headers=headers)
    try:
        with urllib.request.urlopen(req) as res:
            print("STATUS:", res.status)
            print("BODY:", res.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        print("HTTP ERROR CODE:", e.code)
        print("HTTP ERROR BODY:", e.read().decode("utf-8"))
    except Exception as e:
        print("EXCEPTION:", str(e))

check_url("https://mobile-student-monitoring-production.up.railway.app/api/auth/login/teacher/", "NEW MOBILE SERVICE")

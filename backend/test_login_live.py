import urllib.request
import json

url = "https://mobile-student-monitoring-production.up.railway.app/api/auth/login/teacher/"
data = json.dumps({"username": "abbosmath", "password": "abbosmath"}).encode("utf-8")
headers = {"Content-Type": "application/json"}

req = urllib.request.Request(url, data=data, headers=headers)
try:
    with urllib.request.urlopen(req) as res:
        print("LOGIN API SUCCESS STATUS:", res.status)
        print("LOGIN API RESPONSE:", res.read().decode("utf-8"))
except urllib.error.HTTPError as e:
    print("HTTP ERROR CODE:", e.code)
    print("HTTP ERROR BODY:", e.read().decode("utf-8"))
except Exception as e:
    print("EXCEPTION:", str(e))

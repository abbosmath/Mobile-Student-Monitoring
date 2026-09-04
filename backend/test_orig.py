import urllib.request
import json

url = "https://student-monitoring-production.up.railway.app/api/auth/login/teacher/"
data = json.dumps({"username": "abbosmath", "password": "abbosmath"}).encode("utf-8")
headers = {"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"}

req = urllib.request.Request(url, data=data, headers=headers)
try:
    with urllib.request.urlopen(req) as res:
        print("ORIGINAL SERVICE STATUS:", res.status)
        print("ORIGINAL SERVICE BODY:", res.read().decode("utf-8"))
except urllib.error.HTTPError as e:
    print("ORIGINAL SERVICE HTTP ERROR CODE:", e.code)
    print("ORIGINAL SERVICE HTTP ERROR BODY:", e.read().decode("utf-8"))
except Exception as e:
    print("EXCEPTION:", str(e))

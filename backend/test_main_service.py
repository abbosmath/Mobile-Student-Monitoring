import urllib.request
import json

url = "https://student-monitoring-production.up.railway.app/api/auth/login/teacher/"
data = json.dumps({"username": "abbosmath", "password": "abbosmath"}).encode("utf-8")

req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"})

try:
    with urllib.request.urlopen(req) as res:
        print("ORIGINAL SERVICE API STATUS:", res.status)
        print("ORIGINAL SERVICE API BODY:", res.read().decode("utf-8"))
except urllib.error.HTTPError as e:
    print("ORIGINAL SERVICE HTTP ERROR:", e.code)
    print("ORIGINAL SERVICE RESPONSE BODY:", e.read().decode("utf-8"))
except Exception as e:
    print("CONNECTION ERROR:", str(e))

import urllib.request
import json

url = "https://mobile-student-monitoring-production.up.railway.app/api/auth/login/teacher/"
data = json.dumps({"username": "abbosmath", "password": "abbosmath"}).encode("utf-8")

req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"})

try:
    with urllib.request.urlopen(req) as res:
        print("RAILWAY API RESPONSE STATUS:", res.status)
        print("RAILWAY API RESPONSE BODY:", res.read().decode("utf-8"))
except urllib.error.HTTPError as e:
    print("RAILWAY API HTTP ERROR:", e.code)
    print("RAILWAY API RESPONSE BODY:", e.read().decode("utf-8"))
except Exception as e:
    print("CONNECTION ERROR:", str(e))

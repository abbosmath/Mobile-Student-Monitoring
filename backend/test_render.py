import urllib.request
import json

url = "https://mobile-student-monitoring.onrender.com/api/"
req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})

try:
    with urllib.request.urlopen(req) as res:
        print("RENDER API STATUS:", res.status)
        print("RENDER API RESPONSE:", res.read().decode("utf-8"))
except Exception as e:
    print("EXCEPTION:", str(e))

import urllib.request
import json

def test_api(url):
    print(f"Testing URL: {url}")
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req) as res:
            print("STATUS:", res.status)
            print("BODY:", res.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        print("HTTP ERROR CODE:", e.code)
        print("HTTP ERROR BODY:", e.read().decode("utf-8"))
    except Exception as e:
        print("EXCEPTION:", str(e))

test_api("https://student-monitoring-production.up.railway.app/api/")
test_api("https://mobile-student-monitoring-production.up.railway.app/api/")

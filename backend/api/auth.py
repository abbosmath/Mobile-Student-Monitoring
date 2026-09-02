import json
from functools import wraps
from django.core.signing import TimestampSigner, BadSignature, SignatureExpired
from django.http import JsonResponse
from users.models import Teacher, Parent
from students.models import Student

signer = TimestampSigner()

def generate_token(data: dict) -> str:
    """Encodes a payload dictionary into a signed timestamp token."""
    raw_str = json.dumps(data)
    return signer.sign(raw_str)

def verify_token(token: str, max_age: int = 86400 * 30) -> dict | None:
    """Verifies and decodes a signed token. Returns payload dict or None if invalid."""
    if not token:
        return None
    try:
        raw_str = signer.unsign(token, max_age=max_age)
        return json.loads(raw_str)
    except (BadSignature, SignatureExpired, json.JSONDecodeError):
        return None

def get_auth_payload(request):
    """Extracts token from Authorization header (Bearer <token>) or X-API-Token header or query param."""
    auth_header = request.headers.get("Authorization", "")
    token = ""
    if auth_header.startswith("Bearer "):
        token = auth_header[7:].strip()
    elif "X-API-Token" in request.headers:
        token = request.headers["X-API-Token"].strip()
    elif "token" in request.GET:
        token = request.GET["token"].strip()

    return verify_token(token)

def api_auth_required(roles=None):
    """
    Decorator for API views.
    `roles` can be a string ('teacher', 'student') or list of allowed roles.
    """
    if isinstance(roles, str):
        roles = [roles]

    def decorator(view_func):
        @wraps(view_func)
        def _wrapped_view(request, *args, **kwargs):
            payload = get_auth_payload(request)
            if not payload:
                return JsonResponse({"error": "Unauthorized. Invalid or missing token."}, status=401)
            
            user_role = payload.get("role")
            if roles and user_role not in roles:
                return JsonResponse({"error": f"Forbidden. Role '{user_role}' does not have access."}, status=403)
            
            request.api_user = payload
            return view_func(request, *args, **kwargs)
        return _wrapped_view
    return decorator

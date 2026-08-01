from django.http import HttpResponse

def telegram_webhook(request):
    return HttpResponse("Bot service is active.")

from django.conf import settings
from django.contrib.auth.models import Group
from Online_Doctor_Booking.push_notification import (
    get_admin_user_device_token,
    push_notification_mult_devices,
)
from notification.models import Notification
from functions.handle_error import get_object_or_None


def send_push_notification_Admin(message_title, message_body):
    groupName = "Admin_App_User"
    li = get_admin_user_device_token(groupName)

    Data = {"message_title": message_title, "message_body": message_body}
    group = get_object_or_None(Group, name=groupName)
    if group:
        # saveNotification = Notification(group=group, data=Data).save()
        Notification(group=group, data=Data).save()
    if li:
        push_notification_mult_devices(
            li,
            message_title,
            message_body,
            settings.FIREBASE_ADMIN_API_KEY,
        )
        return True
    return False


def send_push_notification_AmbulanceAdmin(message_title, message_body):
    groupName = "Ambulance_Admin"
    li = get_admin_user_device_token(groupName)

    Data = {"message_title": message_title, "message_body": message_body}

    group = get_object_or_None(Group, name=groupName)
    if group:
        # saveNotification = Notification(group=group, data=Data).save()
        Notification(group=group, data=Data).save()
    if li:
        push_notification_mult_devices(
            li,
            message_title,
            message_body,
            settings.FIREBASE_AMBULANCE_ADMIN_API_KEY,
        )

        return True
    return False

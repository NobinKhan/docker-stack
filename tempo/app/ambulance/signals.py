from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from .push_notification import (
    send_push_notification_Admin,
    send_push_notification_AmbulanceAdmin,
)
from Online_Doctor_Booking.push_notification import push_notification_with_data_message
from .models import AmbulanceOrder
from notification.models import Notification


@receiver(post_save, sender=AmbulanceOrder)
def newOrder_Signal(sender, **kwargs):
    instance = kwargs["instance"]

    if kwargs.get("created"):
        mst = "New Ambulance Booking"
        msb = f"Order id {instance.id} booked successfully"
        send_push_notification_Admin(mst, msb)


@receiver(pre_save, sender=AmbulanceOrder)
def updateAmbulanceOrder_signal(sender, **kwargs):
    instance = kwargs["instance"]

    if instance.id:
        previous = AmbulanceOrder.objects.get(id=instance.id)

        if previous.orderStatus != instance.orderStatus:
            # sending push notification to the user
            user_device_reg_id = AmbulanceOrder.objects.filter(id=instance.id).values(
                "user__Device_Registration_Id",
            )[0]["user__Device_Registration_Id"]

            Data = {
                "type": "Ambulance",
                "message_title": "অ্যাম্বুলেন্স অর্ডার স্টেটাস আপডেট হয়েছে",
                "message_body": f"আপনার অর্ডারটি কন্ফার্ম হয়েছে। অনুগ্রহ করে অর্ডার তালিকা দেখু। অর্ডার নম্বর -  {instance.id}",
            }
            user = instance.user
            if user:
                # saveNotification = Notification(user=user, data=Data).save()
                Notification(user=user, data=Data).save()
            if user_device_reg_id is None:
                push_notification_with_data_message(user_device_reg_id, Data)

            if instance.orderStatus == "Confirmed":
                # sending push notification to Ambulance admin
                mst = "New Ambulance Booking"
                msb = f"Order id {instance.id} booked successfully, please call the patient"
                send_push_notification_AmbulanceAdmin(mst, msb)

            if instance.orderStatus == "Completed":
                # sending push notification to admin
                mst = "Order status changed"
                msb = f"Status of the Order id {instance.id} is Completed"
                send_push_notification_Admin(mst, msb)

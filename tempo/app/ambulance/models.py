from django.db import models
from django.contrib.auth import get_user_model
from django.core.validators import RegexValidator
from django.utils.translation import gettext_lazy as _
from django.core.exceptions import ValidationError
from .validators import validate_time


# Global Variables
User = get_user_model()
PROFIT_PERCENTAGE = 20


# Create your models here.
class Ambulance(models.Model):
    ambulanceType = models.CharField(max_length=30, blank=True, null=True)
    minPrice = models.PositiveSmallIntegerField(blank=True, null=True)
    maxPrice = models.PositiveSmallIntegerField(blank=True, null=True)

    class Meta:
        verbose_name_plural = "Ambulances"

    def __str__(self):
        return str(self.ambulanceType) or "BLANK"


class AmbulanceOrder(models.Model):
    statusChoices = (
        ("Pending", "Pending"),
        ("Canceled", "Canceled"),
        ("Confirmed", "Confirmed"),
        ("Completed", "Completed"),
    )
    user = models.ForeignKey(
        User,
        related_name="user",
        on_delete=models.PROTECT,
        blank=True,
        null=True,
    )
    ambulance = models.ForeignKey(
        Ambulance,
        on_delete=models.PROTECT,
        blank=True,
        null=True,
    )
    pickupAddress = models.CharField(max_length=250, blank=True, null=True)
    dropAddress = models.CharField(max_length=250, blank=True, null=True)
    phone_regex = RegexValidator(
        regex=r"^\+(?:[0-9]●?){6,14}[0-9]$",
        message=_(
            "Enter a valid international mobile phone number starting with +(country code)",
        ),
    )
    contactNumber = models.CharField(
        validators=[phone_regex],
        verbose_name=_("Contact Phone Number"),
        max_length=17,
        blank=True,
        null=True,
    )
    travelTime = models.DateTimeField(validators=[validate_time], blank=True, null=True)
    SpecialNote = models.TextField(blank=True, null=True)
    totalBill = models.PositiveIntegerField(blank=True, null=True)
    cbProfit = models.PositiveIntegerField(blank=True, null=True)
    orderStatus = models.CharField(
        max_length=15,
        choices=statusChoices,
        default="Pending",
        blank=True,
        null=True,
    )
    isPaidToCB = models.BooleanField(
        default=False,
        blank=True,
        null=True,
    )  # if true then CareBox Got the money but need status completed

    isActive = models.BooleanField(
        default=True,
        blank=True,
        null=True,
    )  # if false that means user is deleted
    created = models.DateTimeField(auto_now=True, null=True)
    updated = models.DateTimeField(auto_now_add=True, null=True)
    updatedBy = models.ForeignKey(
        User,
        related_name="updatedby",
        on_delete=models.PROTECT,
        blank=True,
        null=True,
    )

    class Meta:
        verbose_name_plural = "AmbulanceOrders"

    def __str__(self):
        return str(self.ambulance)

    def clean(self):
        if self.id:
            if not self.updatedBy and self.isPaidToCB:
                msg = "it's Not the time to change Paid Field: Not Saved"
                raise ValidationError(msg)

            if self.orderStatus == "Confirmed" and not self.totalBill:
                msg = "Without Total Bill You can't change status: Not Saved"
                raise ValidationError(msg)

            if self.isPaidToCB and self.orderStatus != "Completed":
                msg = (
                    "Without changing status to completed you can't get paid: Not Saved"
                )
                raise ValidationError(msg)

            if self.ambulance.minPrice and self.totalBill and self.ambulance.maxPrice:
                if (
                    self.ambulance.minPrice > self.totalBill
                    or self.ambulance.maxPrice < self.totalBill
                ):
                    msg = "Bill must be in between min and max price of ambulance: Not Saved"
                    raise ValidationError(msg)

            instance = AmbulanceOrder.objects.get(pk=self.id)
            if self.user != instance.user:
                msg = "User cannot be changed: Not Saved"
                raise ValidationError(msg)

            if instance.orderStatus == "Completed" and self.orderStatus != "Completed":
                msg = "You Can't change status of completed order: Not Saved"
                raise ValidationError(msg)

            if (
                instance.orderStatus == "Completed"
                and self.totalBill != instance.totalBill
            ):
                msg = "You Can't change Bill Amount of completed order: Not Saved"
                raise ValidationError(msg)

            if (
                instance.orderStatus == "Completed"
                and self.isPaidToCB != instance.isPaidToCB
            ):
                msg = "You Can't change this field of completed order: Not Saved"
                raise ValidationError(msg)

            if (
                instance.orderStatus == "Pending"
                and self.totalBill
                and self.orderStatus != "Confirmed"
            ):
                msg = "You Can't only change bill amount of pending order: Not Saved"
                raise ValidationError(msg)

            if (
                instance.orderStatus == "Pending"
                and not self.totalBill
                and self.orderStatus == "Confirmed"
            ):
                msg = "You Can't only change order status of pending order: Not Saved"
                raise ValidationError(msg)

            if (
                instance.orderStatus == "Confirmed"
                and self.orderStatus == "Completed"
                and not self.isPaidToCB
            ):
                msg = (
                    "You must have to pay to Care Box to complete this order: Not Saved"
                )
                raise ValidationError(msg)

    def save(self, *args, **kwargs):
        if self._state.adding is True:
            if (
                not self.user
                or not self.ambulance
                or not self.pickupAddress
                or not self.dropAddress
            ):
                return

            if not self.contactNumber:
                if self.user.Phone and self.user.Phone.startswith("+"):
                    self.contactNumber = self.user.Phone
                else:
                    self.contactNumber = f"+88{self.user.Phone}"

        if self.id:
            if not self.updatedBy and self.isPaidToCB:
                return
            if self.orderStatus == "Confirmed" and not self.totalBill:
                return
            if self.isPaidToCB and self.orderStatus != "Completed":
                return

            if self.ambulance.minPrice and self.totalBill and self.ambulance.maxPrice:
                if (
                    self.ambulance.minPrice > self.totalBill
                    or self.ambulance.maxPrice < self.totalBill
                ):
                    return
            if not self.totalBill:
                self.cbProfit = None
            if self.orderStatus == "Confirmed" and self.totalBill:
                self.cbProfit = (self.totalBill * PROFIT_PERCENTAGE) / 100
            if self.orderStatus == "Canceled":
                self.totalBill, self.cbProfit = None, None
        super().save(*args, **kwargs)

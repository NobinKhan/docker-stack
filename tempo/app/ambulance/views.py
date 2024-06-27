### Django Imports
from django.utils.timezone import datetime

#### all   Rest framework  import ............................
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser

#### Models
from ambulance.models import Ambulance, AmbulanceOrder

#### Serializers
from .serializers import (
    AdminAmbulanceOrder_serilaizer,
    Ambulance_serializer,
    AmbulanceOrder_serializer,
)


#### Nobin - Start ####


class AmbulanceList(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        ambulances = Ambulance.objects.all()
        serializer = Ambulance_serializer(ambulances, many=True)
        return Response(serializer.data)


class AmbulanceOrderList(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        ambulanceOrders = (
            AmbulanceOrder.objects.filter(user=user, isActive=True)
            .values(
                "id",
                "orderStatus",
                "totalBill",
                "ambulance__ambulanceType",
                "pickupAddress",
                "dropAddress",
                "travelTime",
            )
            .order_by("-id")
        )

        if not ambulanceOrders:
            return Response({"message": "you don't have any orders yet"})
        serializer = AmbulanceOrder_serializer(ambulanceOrders, many=True)
        return Response(serializer.data)

    def post(self, request, formate=None):
        # Null data validation
        if request.data.get("ambulance") is None:
            return Response(
                {"message": ["ambulance field, Null Data Not Allowed."]},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if request.data.get("pickupAddress") is None:
            return Response(
                {"message": "pickupAddress field, Null Data Not Allowed."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if request.data.get("dropAddress") is None:
            return Response(
                {"message": "dropAddress field, Null Data Not Allowed."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if not request.data.get("travelTime") or request.data.get("travelTime") is None:
            return Response(
                {"message": "travelTime field, Null Data Not Allowed."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Time validation
        if not request.data.get("travelDate"):
            return Response(
                {"message": "travelDate field is required."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if request.data.get("travelTime"):
            try:
                strdate = datetime.strptime(
                    request.data.get("travelDate"),
                    "%Y-%m-%d",
                ).date()
            except Exception as e:
                print("error: ", e)
                return Response(
                    {"message": "Invalid Date Formate, Use this formate 'YYYY-MM-DD'"},
                    status=status.HTTP_406_NOT_ACCEPTABLE,
                )
            try:
                strtime = datetime.strptime(
                    request.data.get("travelTime"),
                    "%H:%M",
                ).time()
            except Exception:
                return Response(
                    {"message": "Invalid Time Formate, Use this formate 'HH:MM' 24H"},
                    status=status.HTTP_406_NOT_ACCEPTABLE,
                )

            request.data["travelTime"] = f"{strdate}T{strtime}"

        serializer = AmbulanceOrder_serializer(data=request.data)
        if serializer.is_valid():
            serializer.save(user=request.user)
            if serializer.instance.id:
                return Response(
                    {
                        "message": f"New ambulance order posted successfully, Order Booking ID: {serializer.instance.id}",
                    },
                )
        if serializer.errors.get("contactNumber"):
            return Response(
                {"message": serializer.errors.get("contactNumber")[0]},
                status=status.HTTP_406_NOT_ACCEPTABLE,
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


#### Nobin - Stop ####


class Get_Ambulance_Booking_Admin_API(APIView):
    """Get API of last 50 Ambulance booking for the Admin"""

    permission_classes = [IsAdminUser]

    def get(self, request):
        query = AmbulanceOrder.objects.all().order_by("-id")[:50]

        serializer = AdminAmbulanceOrder_serilaizer(query, many=True)

        if serializer.data:
            return Response(serializer.data)
        return Response({"message": "Data not found"})

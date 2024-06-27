#### all   Rest framework  import ............................
from rest_framework import status
from django.http import Http404
from rest_framework.views import APIView
from rest_framework.response import Response
from django.db.models import Sum
from .permissions import IsAmbulance_Admin

#### Extra
#### Extra
from django.db.models import Q

#### Models
from .models import (
    AmbulanceOrder,
)

#### Serializers
from .serializers import (
    AmbulanceOrderStatusUpdateSerializer,
)


class Orderlist(APIView):
    permission_classes = [IsAmbulance_Admin]

    def get(self, request, format=None):
        pk = request.query_params.get("orderid")
        if pk:
            query = AmbulanceOrder.objects.filter(id=pk).values(
                "id",
                "user__Name",
                "totalBill",
                "orderStatus",
                "contactNumber",
                "dropAddress",
                "pickupAddress",
            )

            return Response({"AmbulanceOrderDetails": query})

        query = (
            AmbulanceOrder.objects.all()
            .values(
                "id",
                "user__Name",
                "totalBill",
                "orderStatus",
                "contactNumber",
                "dropAddress",
                "pickupAddress",
            )
            .order_by("-id")[:50]
        )

        return Response({"AmbulanceOrderDetails": query})


class OrderUpdate(APIView):
    permission_classes = [IsAmbulance_Admin]

    def get_object(self, pk):
        try:
            return AmbulanceOrder.objects.get(pk=pk)
        except AmbulanceOrder.DoesNotExist:
            raise Http404

    def put(self, request, pk, format=None):
        snippet = self.get_object(pk)
        serializer = AmbulanceOrderStatusUpdateSerializer(snippet, data=request.data)
        total_bill = AmbulanceOrder.objects.filter(id=pk).values("totalBill")

        if request.data == {}:
            return Response("Please Provide Correct Data  in Body")

        elif request.data["orderStatus"] is None:
            return Response("Please Provide Correct Data  in Body")

        elif not request.data["orderStatus"] == "Completed":
            return Response("Please Provide Correct Updatedata  in Orderstatus")

        else:
            if total_bill[0]["totalBill"] is None:
                return Response("Please Give total_bill from Admin")

            if serializer.is_valid():
                serializer.save()
                return Response("OrderStatus Successfully Updated")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ProfitOrder(APIView):
    permission_classes = [IsAmbulance_Admin]

    def get(self, request, format=None):
        pk = request.query_params.get("orderid")
        CareboxRecived = AmbulanceOrder.objects.filter(isPaidToCB=True).aggregate(
            Sum("totalBill"),
        )
        Total_Earning = AmbulanceOrder.objects.filter(
            Q(orderStatus="Pending")
            | Q(orderStatus="Confirmed")
            | Q(orderStatus="Completed"),
        ).aggregate(Sum("totalBill"))

        if pk:
            query = AmbulanceOrder.objects.filter(id=pk).values(
                "id",
                "totalBill",
                "cbProfit",
                "isPaidToCB",
            )

            return Response(
                {
                    "ProfitOrderDetails": query,
                    "CareboxRecived": CareboxRecived["totalBill__sum"],
                    "Total_Earning": Total_Earning["totalBill__sum"],
                },
            )

        else:
            query = (
                AmbulanceOrder.objects.all()
                .values("id", "totalBill", "cbProfit", "isPaidToCB")
                .order_by("-id")[:50]
            )

        return Response(
            {
                "ProfitOrderDetails": query,
                "CareboxRecived": CareboxRecived["totalBill__sum"],
                "Total_Earning": Total_Earning["totalBill__sum"],
            },
        )


class DashBoard(APIView):
    permission_classes = [IsAmbulance_Admin]

    def get(self, request, format=None):
        Fromdate = request.query_params.get("Fromdate")
        Todate = request.query_params.get("Todate")
        if not Fromdate:
            Fromdate = "2000-01-01"
        if not Todate:
            Todate = "3000-01-01"

            Todate += " 23:59:59+06"
            Fromdate += " 00:00:00+06"

        CareboxRecived = AmbulanceOrder.objects.filter(
            Q(isPaidToCB=True) & Q(created__gte=Fromdate) & Q(created__lte=Todate),
        ).aggregate(Sum("cbProfit"))
        Total_Earning = AmbulanceOrder.objects.filter(
            Q(orderStatus="Completed")
            & Q(created__gte=Fromdate)
            & Q(created__lte=Todate),
        ).aggregate(Sum("totalBill"))
        PayableToCB = (
            AmbulanceOrder.objects.filter(
                Q(orderStatus="Completed")
                & Q(created__gte=Fromdate)
                & Q(created__lte=Todate),
            )
            .exclude(isPaidToCB=True)
            .aggregate(Sum("cbProfit"))
        )
        NoOfOrder = AmbulanceOrder.objects.all().count()

        return Response(
            {
                "PayableToCB": PayableToCB["cbProfit__sum"],
                "CareboxRecived": CareboxRecived["cbProfit__sum"],
                "Total_Earning": Total_Earning["totalBill__sum"],
                "NoOfOrder": NoOfOrder,
            },
        )


class ReportDownload(APIView):
    permission_classes = [IsAmbulance_Admin]

    def get(self, request, format=None):
        Fromdate = request.query_params.get("Fromdate")
        Todate = request.query_params.get("Todate")
        if not Fromdate:
            Fromdate = "2000-01-01"
        if not Todate:
            Todate = "3000-01-01"

            Todate += " 23:59:59+06"
            Fromdate += " 00:00:00+06"
            Order = (
                AmbulanceOrder.objects.filter(
                    Q(created__gte=Fromdate) & Q(created__lte=Todate),
                )
                .order_by("-id")
                .values("id", "totalBill", "orderStatus", "created", "cbProfit")
            )

        return Response({"NoOfOrder": Order})

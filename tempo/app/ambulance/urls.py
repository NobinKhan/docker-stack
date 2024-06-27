from django.urls import path


from .views import (
    AmbulanceList,
    AmbulanceOrderList,
    Get_Ambulance_Booking_Admin_API,
)

from ambulance.DashBoardAdminviews import (
    DashBoard,
    OrderUpdate,
    Orderlist,
    ProfitOrder,
    ReportDownload,
)


app_name = "ambulance"


urlpatterns = [
    ######## Nobin ########
    path("ambulance_list/", AmbulanceList.as_view(), name="ambulance_list"),
    path("booking_history/", AmbulanceOrderList.as_view(), name="booking_history"),
    path("new_order/", AmbulanceOrderList.as_view(), name="new_order"),
    ######## Nobin ######
    ######## Sifat ########
    # path('Admin/order_list/<int:pk>/',DashBoardAdminviews.Orderlist,name='Ambulanceorder_list'),
    path("Admin/order_list/", Orderlist.as_view(), name="Ambulanceorder_list"),
    path("Admin/profit_order/", ProfitOrder.as_view(), name="ProfitOrder_list"),
    path("Admin/Dashboard/", DashBoard.as_view(), name="DashBoard"),
    path("Admin/report_details/", ReportDownload.as_view(), name="ReportDownload"),
    path("Admin/orderstatusUpdate/<int:pk>", OrderUpdate.as_view(), name="OrderUpdate"),
    ######## Sifat ########
    #### Barun ####
    path(
        "get_ambulance_booking_admin_api/",
        Get_Ambulance_Booking_Admin_API.as_view(),
        name="Get_Ambulance_Booking_Admin_API",
    ),
]

from rest_framework import serializers

from .models import (
    Ambulance,
    AmbulanceOrder,
)


class AmbulanceOrderStatusUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = AmbulanceOrder
        fields = ("orderStatus",)
        extra_kwargs = {
            "orderStatus": {"required": True},
        }


class Ambulance_serializer(serializers.ModelSerializer):
    class Meta:
        model = Ambulance
        fields = ("id", "ambulanceType", "minPrice", "maxPrice")


class AdminAmbulanceOrder_serilaizer(serializers.ModelSerializer):
    class Meta:
        model = AmbulanceOrder
        fields = (
            "id",
            "totalBill",
            "orderStatus",
            "contactNumber",
            "dropAddress",
            "pickupAddress",
        )


class AmbulanceOrder_serializer(serializers.ModelSerializer):
    ambulanceType = serializers.SerializerMethodField(read_only=True)

    def __init__(self, *args, **kwargs):
        if args:
            if not isinstance(args[0], dict):
                # if type(args[0]) != type(dict()):
                fields = list(dict(args[0][0]).keys())
            else:
                fields = list(args[0].keys())
            super().__init__(*args, **kwargs)

            if "ambulance__ambulanceType" in fields:
                fields[fields.index("ambulance__ambulanceType")] = "ambulanceType"
            if fields is not None:
                # Drop any fields that are not specified in the `fields` argument.
                allowed = set(fields)
                existing = set(self.fields)
                for field_name in existing - allowed:
                    self.fields.pop(field_name)
        else:
            super().__init__(*args, **kwargs)

    class Meta:
        model = AmbulanceOrder
        fields = "__all__"
        extra_kwargs = {
            "ambulance": {"required": True},
            "pickupAddress": {"required": True},
            "dropAddress": {"required": True},
            "travelTime": {"required": True},
        }

    # def create(self, validated_data):
    #     print(validated_data)
    #     instance = AmbulanceOrder(**validated_data)
    #     instance.save()
    #     return instance

    def get_ambulanceType(self, obj):
        # print(obj)
        return obj.get("ambulance__ambulanceType")

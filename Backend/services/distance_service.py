from math import asin, cos, radians, sin, sqrt


EARTH_RADIUS_KM = 6371.0
AVERAGE_SPEED_KMH = 25.0
BASE_DELIVERY_FEE = 15000.0
FREE_THRESHOLD_KM = 3.0
EXTRA_KM_PRICE = 5000.0


def calculate_distance_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    lat1_rad = radians(lat1)
    lon1_rad = radians(lon1)
    lat2_rad = radians(lat2)
    lon2_rad = radians(lon2)

    delta_lat = lat2_rad - lat1_rad
    delta_lon = lon2_rad - lon1_rad

    haversine = (
        sin(delta_lat / 2) ** 2
        + cos(lat1_rad) * cos(lat2_rad) * sin(delta_lon / 2) ** 2
    )
    arc = 2 * asin(sqrt(haversine))
    return round(EARTH_RADIUS_KM * arc, 2)


def estimate_delivery_time(distance_km: float) -> int:
    if distance_km <= 0:
        return 0
    eta_minutes = (distance_km / AVERAGE_SPEED_KMH) * 60
    return max(1, int(round(eta_minutes)))


def calculate_delivery_fee(distance_km: float) -> float:
    if distance_km <= FREE_THRESHOLD_KM:
        return BASE_DELIVERY_FEE
    return round(distance_km * EXTRA_KM_PRICE, 0)

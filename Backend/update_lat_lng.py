"""
Script cập nhật lat/lng cho các seller có address_shop nhưng chưa có tọa độ.
Sử dụng Nominatim (OpenStreetMap) để geocode địa chỉ.

Cách chạy:
    python update_lat_lng.py
"""

import time
from geopy.geocoders import Nominatim
from sqlalchemy import or_
from database import SessionLocal
from models import User


def geocode_address(geolocator: Nominatim, address: str):
    """Geocode một địa chỉ, trả về (lat, lng) hoặc None."""
    try:
        location = geolocator.geocode(address, timeout=10)
        if location:
            return location.latitude, location.longitude
    except Exception as e:
        print(f"  [LỖI] Không geocode được '{address}': {e}")
    return None


def main():
    db = SessionLocal()
    geolocator = Nominatim(user_agent="food_delivery_app_geocoder")

    try:
        # Lấy tất cả seller có address_shop nhưng chưa có lat hoặc lng
        sellers = (
            db.query(User)
            .filter(
                User.role == "seller",
                User.address_shop.isnot(None),
                User.address_shop != "",
                or_(User.lat.is_(None), User.lng.is_(None)),
            )
            .all()
        )

        if not sellers:
            print("Không có seller nào cần cập nhật lat/lng.")
            return

        print(f"Tìm thấy {len(sellers)} seller cần cập nhật tọa độ.\n")

        updated = 0
        failed = 0

        for seller in sellers:
            print(f"[{seller.id}] {seller.name_shop or seller.full_name}")
            print(f"  Địa chỉ: {seller.address_shop}")

            result = geocode_address(geolocator, seller.address_shop)

            if result:
                lat, lng = result
                seller.lat = lat
                seller.lng = lng
                db.commit()
                updated += 1
                print(f"  => lat={lat}, lng={lng} ✓")
            else:
                failed += 1
                print(f"  => Không tìm thấy tọa độ ✗")

            # Nominatim yêu cầu tối thiểu 1 giây giữa các request
            time.sleep(1.1)

        print(f"\nHoàn tất: {updated} cập nhật thành công, {failed} thất bại.")

    finally:
        db.close()


if __name__ == "__main__":
    main()

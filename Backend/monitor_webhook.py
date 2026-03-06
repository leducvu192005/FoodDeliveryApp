
import time
from datetime import datetime

print("="*70)
print("🔍 WEBHOOK MONITOR - Listening for Sepay webhooks...")
print("="*70)
print(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print()
print("Monitoring: http://localhost:8000/api/sepay/webhook")
print()
print("✅ Mỗi khi Sepay gửi webhook, bạn sẽ thấy log ở đây")
print("❌ Nếu không thấy log, nghĩa là Sepay không gọi đến backend")
print()
print("Press Ctrl+C to stop")
print("="*70)
print()

try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    print("\n\n🛑 Monitor stopped")

import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart


SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587
SMTP_EMAIL = "khaclong02042005@gmail.com"       
SMTP_PASSWORD = "jssf baja ndqw ydjt"      


def send_otp_email(to_email: str, otp: str):
    msg = MIMEMultipart()
    msg["From"] = SMTP_EMAIL
    msg["To"] = to_email
    msg["Subject"] = "Ma OTP dat lai mat khau - Food Delivery"

    body = f"""Xin chao,

Ma OTP cua ban la: {otp}

Ma nay co hieu luc trong 10 phut.
Vui long khong chia se ma nay cho bat ky ai.

Tran trong,
Food Delivery App"""

    msg.attach(MIMEText(body, "plain", "utf-8"))

    with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
        server.starttls()
        server.login(SMTP_EMAIL, SMTP_PASSWORD)
        server.send_message(msg)

from PIL import Image, ImageDraw, ImageFont
import os

# Yollar
icon_path = "/home/burak/uni_app/assets/icons/unisec-icon-ink-1024.png"
bg_path = "/home/burak/.gemini/antigravity/brain/7f691aaf-b955-4c78-b4dc-07a25f928901/unisec_feature_graphic_1781797911715.png"
output_dir = "/home/burak/uni_app/assets/play_store"

os.makedirs(output_dir, exist_ok=True)

# 1. Uygulama Simgesi (512x512)
if os.path.exists(icon_path):
    try:
        img = Image.open(icon_path).convert("RGBA")
        img_512 = img.resize((512, 512), Image.Resampling.LANCZOS)
        # Arka plan saydam ise Google Play kabul etmeyebilir, ama bu ikon zaten siyah arkaplanli
        # O yüzden direkt kaydediyoruz. Google Play PNG ister.
        icon_out = os.path.join(output_dir, "app_icon_512x512.png")
        img_512.save(icon_out)
        print(f"Uygulama Simgesi Hazır: {icon_out}")
    except Exception as e:
        print(f"İkon oluşturulurken hata: {e}")
else:
    print(f"İkon bulunamadı: {icon_path}")

# 2. Özellik Grafiği (1024x500)
if os.path.exists(bg_path):
    try:
        bg = Image.open(bg_path).convert("RGBA")
        
        # Orijinal resim genelde 1024x1024 oluyor, biz 1024x500'lük ortasını alacağız.
        width, height = bg.size
        new_height = int(width * (500 / 1024))
        
        # Eğer resim tam kare ise (1024x1024) ortadan kes
        if height > new_height:
            top = (height - new_height) // 2
            bottom = top + new_height
            bg_cropped = bg.crop((0, top, width, bottom))
        else:
            bg_cropped = bg.resize((1024, 500), Image.Resampling.LANCZOS)
            
        bg_cropped = bg_cropped.resize((1024, 500), Image.Resampling.LANCZOS)
        
        # Logoyu tam ortaya ekleyelim
        if os.path.exists(icon_path):
            logo = Image.open(icon_path).convert("RGBA")
            logo_size = 280
            logo = logo.resize((logo_size, logo_size), Image.Resampling.LANCZOS)
            
            # Yuvarlak veya köşeleri oval yapmak için (opsiyonel)
            
            x = (1024 - logo_size) // 2
            y = (500 - logo_size) // 2
            bg_cropped.paste(logo, (x, y), logo)
            
        # JPEG olarak kaydetmek daha güvenlidir, arka plan transparansa hata vermesin
        fg_out = os.path.join(output_dir, "feature_graphic_1024x500.png")
        bg_cropped.convert("RGB").save(fg_out, "PNG")
        print(f"Özellik Grafiği Hazır: {fg_out}")
    except Exception as e:
        print(f"Özellik Grafiği oluşturulurken hata: {e}")
else:
    print(f"Arka plan bulunamadı: {bg_path}")

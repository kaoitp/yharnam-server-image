# Yharnam Together server image สำหรับ Unraid

[ไทย](README.md) | [English](README.en.md)

Repo นี้สร้าง image `linux/amd64` จาก [release ของ Yharnam Together](https://github.com/Amanises-Yharnam-Together/BBSC-Yharnam-Together/releases) รวม prerelease โดยใช้ Dockerfile และ protobuf submodule ของ tag นั้น ไม่มีตัวเกมหรือ client อยู่ใน image ตรวจสอบ tag ให้ตรงกับ client ของทุกคนก่อนเล่น ตัวอย่าง `v1.4.0` เป็นเพียงตัวอย่าง ไม่ได้หมายความว่า image รุ่นนั้นพร้อมแล้ว ให้ตรวจผล Actions และ package ก่อนติดตั้ง

## การ build และเลือกเวอร์ชัน

Actions ตรวจวันละครั้งเวลา 03:23 UTC โดยเลือก release ที่เผยแพร่ล่าสุดตาม `published_at` รวม prerelease ไม่รวม draft จากนั้น checkout tag, ดึง protobuf ตาม commit ที่ระบุ, build และทดสอบว่า server ตอบคำสั่ง admin และสร้าง `link_key.bin` ก่อน push ไป `ghcr.io/kaoitp/yharnam-server:<tag>` พร้อมปรับ `latest` ให้ชี้ไปยัง image ของ release ล่าสุดดังกล่าว แม้เป็น prerelease; การสั่ง build release เก่าด้วยตนเองจะไม่เปลี่ยน `latest` และไม่มีการสั่ง Unraid อัปเดต หากมีหลาย release ระหว่างรอบตรวจ จะเลือกเฉพาะ release ที่เผยแพร่ล่าสุด: รุ่นอื่นสั่งสร้างเองได้ที่ Actions → Build upstream server → Run workflow ใส่ tag ของ release ที่เผยแพร่แล้ว รอผลสำเร็จก่อนใช้งาน

Tag เวอร์ชันที่มีอยู่จะถูกข้าม ไม่สร้างทับ; `latest` เปลี่ยนได้ตาม release ใหม่ จึงควรใช้ tag เวอร์ชันหรือ digest ที่ตรงกับ client เพื่อควบคุมการอัปเดต โดยเฉพาะเมื่อสั่ง pull หรือสร้าง container ใหม่; workflow จะหยุดเมื่อ registry ตอบข้อผิดพลาดอื่นนอกจากไม่พบ tag ตรวจ log หากล้มเหลว Package เดิมที่ไม่ได้เชื่อม repo นี้อาจต้องเพิ่มสิทธิ์ Actions ใน package settings ก่อน อย่าให้ workflow ภายนอกเขียน tag เดียวกันพร้อมกัน เพราะ GHCR ไม่ได้ป้องกันการเปลี่ยน tag ตรวจ digest หากต้องการตรึง image ให้แน่นอน upstream อาจแก้ tag หลังเผยแพร่ได้; image ที่สร้างแล้วจะไม่เปลี่ยนตามโดยอัตโนมัติ

## สิทธิ์ GHCR

หลัง push ครั้งแรกเปิด GitHub → โปรไฟล์ `kaoitp` → Packages → `yharnam-server` → Package settings → Change visibility → Public หากต้องการให้ Unraid pull โดยไม่ล็อกอิน (public เปิดให้ทุกคนอ่าน image ได้) หรือคง Private และล็อกอิน GHCR บน Unraid ด้วยบัญชีที่มีสิทธิ์อ่านและ classic PAT ที่มี `read:packages` ผ่าน `docker login ghcr.io` โดยป้อน token แบบโต้ตอบ ไม่ใส่ใน compose หรือแชต ดู [คู่มือ GitHub](https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility) หาก push ไม่ผ่านให้ตรวจ Settings → Actions → General → Workflow permissions และ Package settings → Manage Actions access ว่า repo นี้เขียน package ได้ GitHub อาจจำกัดการเปลี่ยน visibility กลับหลังเผยแพร่

## ติดตั้งบน Unraid

1. ต้องมี Docker และ Compose บน Unraid แบบ x86-64; ตรวจ tag ที่ build สำเร็จและตรงกับ client ทุกเครื่อง คัดลอก `compose.yaml` ไปโฟลเดอร์สำหรับโครงการ เช่น `/boot/config/yharnam-server` แล้วแก้ `image:` ให้ตรง tag ที่ต้องการ
2. ใน Unraid terminal สร้างโฟลเดอร์ข้อมูลใหม่และให้สิทธิ์ user ของ image (10001:10001) เฉพาะโฟลเดอร์นี้ อย่าใช้คำสั่งเปลี่ยนเจ้าของกับโฟลเดอร์ที่มีข้อมูลอื่น:

   ```sh
   mkdir -p /mnt/user/appdata/yharnam-server
   chown 10001:10001 /mnt/user/appdata/yharnam-server
   chmod 750 /mnt/user/appdata/yharnam-server
   ```

   หากโฟลเดอร์มีข้อมูลอยู่แล้ว ให้ตรวจสิทธิ์และสำรองข้อมูลก่อน ไม่สั่ง `chown -R` โดยไม่ตรวจสอบ `/data` เก็บฐานข้อมูล โลก การตั้งค่า และ `link_key.bin`; ควรอยู่บน storage ภายในที่เชื่อถือได้
3. จากโฟลเดอร์ที่มี compose รัน `docker compose pull` แล้ว `docker compose up -d` ตรวจ `docker compose logs -f shadnet` และ `docker compose ps` ยุติการดู log ด้วย Ctrl+C คำสั่งเหล่านี้ควบคุม instance นี้เท่านั้น
4. ใช้ host network ตรวจว่าไม่มีบริการอื่นใช้ UDP 31314, TCP 31315 และ 20443 และอนุญาตเฉพาะผู้เล่นที่เชื่อถือได้ผ่าน firewall/VPN ตามความจำเป็น TCP 31313 และ stats 31320 ไม่ควรเปิดสาธารณะ พอร์ต 31315 และ 20443 เป็น HTTP แบบไม่เข้ารหัส ดู [hosting upstream](https://github.com/Amanises-Yharnam-Together/BBSC-Yharnam-Together/blob/v1.4.0/server/hosting/README.md) สำหรับรายละเอียด จากนั้นตั้ง IP ของ Unraid ใน client

`restart: unless-stopped` เริ่ม container เดิมใหม่หลังรีบูต แต่ไม่ pull image ใหม่ หลีกเลี่ยงเครื่องมือ auto-update สำหรับ container นี้

## สำรอง อัปเดต และย้อนกลับ

ทำเมื่อทุกคนออกจากเกมแล้วเท่านั้น:

1. ในโฟลเดอร์ compose รัน `docker compose stop` รอให้หยุดเรียบร้อย เพื่อให้ SQLite และ world journal อยู่ในสถานะสอดคล้อง
2. คัดลอก **ทั้งโฟลเดอร์** `/mnt/user/appdata/yharnam-server` รวมไฟล์ซ่อน สิทธิ์ และ `link_key.bin` ไปที่ backup แยกจาก Unraid พร้อมเก็บสำเนา `compose.yaml` และ tag/digest เดิมไว้ ป้องกันการเข้าถึง backup เพราะมีข้อมูลบัญชีและกุญแจของ server ตรวจว่าสำรองเสร็จและทดสอบกู้คืนบนเครื่องแยกก่อนพึ่งพา backup
3. แก้ tag ใน `compose.yaml` ให้ตรง client รุ่นใหม่ ตรวจว่า Actions สำหรับ tag นั้นสำเร็จ แล้วรัน `docker compose pull` และ `docker compose up -d` ตรวจ log ก่อนให้ผู้เล่นเข้า
4. หากต้องย้อนกลับ ให้หยุด container อีกครั้ง เก็บสำเนาข้อมูลปัจจุบันแยกไว้ แล้วกู้ทั้งโฟลเดอร์จาก backup ที่สร้างก่อนอัปเดตและเปลี่ยน tag กลับเป็นรุ่นเดิม จากนั้น `docker compose up -d` การกู้ backup จะทำให้ความคืบหน้าหลัง backup หายไป; การใช้ข้อมูลที่รุ่นใหม่เขียนแล้วกับ server รุ่นเก่าอาจเข้ากันไม่ได้ อย่าแทนที่ `link_key.bin` ด้วยกุญแจใหม่เพราะ client อาจไม่เชื่อถือ server เดิม

การทดสอบใน workflow ตรวจเฉพาะการเริ่ม server ไม่ยืนยัน multiplayer หรือ Unraid จริง


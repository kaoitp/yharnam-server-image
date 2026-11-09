# Yharnam Together server image สำหรับ Unraid

[ไทย](README.md) | [English](README.en.md)

Repo นี้สร้าง image `linux/amd64` จาก [release ของ Yharnam Together](https://github.com/Amanises-Yharnam-Together/BBSC-Yharnam-Together/releases) รวม prerelease โดยใช้ Dockerfile และ protobuf submodule ของ tag นั้น ไม่มีตัวเกมหรือ client อยู่ใน image ตรวจสอบ tag ให้ตรงกับ client ของทุกคนก่อนเล่น Template ใช้ image `yharnam-server-tailscale:latest`; `latest` เปลี่ยนได้และอาจไม่ตรงกับ client ให้ตรวจผล Actions และ package ก่อนติดตั้ง

## การ build และเลือกเวอร์ชัน

Actions ตรวจวันละครั้งเวลา 03:23 UTC โดยเลือก release ที่เผยแพร่ล่าสุดตาม `published_at` รวม prerelease ไม่รวม draft จากนั้น checkout tag, ดึง protobuf ตาม commit ที่ระบุ, build และทดสอบว่า server ตอบคำสั่ง admin และสร้าง `link_key.bin` ก่อน push ไป `ghcr.io/kaoitp/yharnam-server:<tag>` จากนั้นสร้าง tag `-r2` ที่ระบุหมายเลข release ใน server และตรวจจาก log ก่อนปรับ `latest` ให้ชี้ไปยัง image ของ release ล่าสุดดังกล่าว แม้เป็น prerelease; การสั่ง build release เก่าด้วยตนเองจะไม่เปลี่ยน `latest` และไม่มีการสั่ง Unraid อัปเดต หากมีหลาย release ระหว่างรอบตรวจ จะเลือกเฉพาะ release ที่เผยแพร่ล่าสุด: รุ่นอื่นสั่งสร้างเองได้ที่ Actions → Build upstream server → Run workflow ใส่ tag ของ release ที่เผยแพร่แล้ว รอผลสำเร็จก่อนใช้งาน

Tag เดิมที่ไม่มี suffix และ `-ts2` อาจรายงาน server เป็น `dev`; ใช้ `-r2` สำหรับ image ปกติ หรือ `-ts3` สำหรับ Unraid. Tag เวอร์ชันที่มีอยู่จะถูกข้าม ไม่สร้างทับ; `latest` เปลี่ยนได้ตาม release ใหม่ จึงควรใช้ tag เวอร์ชันหรือ digest ที่ตรงกับ client เพื่อควบคุมการอัปเดต โดยเฉพาะเมื่อสั่ง pull หรือสร้าง container ใหม่; workflow จะหยุดเมื่อ registry ตอบข้อผิดพลาดอื่นนอกจากไม่พบ tag ตรวจ log หากล้มเหลว Package เดิมที่ไม่ได้เชื่อม repo นี้อาจต้องเพิ่มสิทธิ์ Actions ใน package settings ก่อน อย่าให้ workflow ภายนอกเขียน tag เดียวกันพร้อมกัน เพราะ GHCR ไม่ได้ป้องกันการเปลี่ยน tag ตรวจ digest หากต้องการตรึง image ให้แน่นอน upstream อาจแก้ tag หลังเผยแพร่ได้; image ที่สร้างแล้วจะไม่เปลี่ยนตามโดยอัตโนมัติ

Image สำหรับ Unraid แยกเป็น `ghcr.io/kaoitp/yharnam-server-tailscale:<tag>-ts3` ซึ่งสร้างจาก image เวอร์ชันเดียวกัน (เช่น client `v1.4.0` ใช้ `v1.4.0-ts3`) โดยให้ hook เริ่มด้วย root แล้วใช้ gosu ลดสิทธิ์ server เป็น UID 10001 ก่อนเริ่ม; Tailscale daemon ยังคงต้องใช้สิทธิ์สำหรับจัดการเครือข่าย บรรจุ Tailscale 1.104.5 พร้อมตรวจ checksum ตอน build เพื่อลดการดาวน์โหลดขณะเริ่ม container; รุ่น Tailscale นี้จะไม่อัปเดตเอง ต้องมี image รุ่นใหม่ ตรวจผล job `tailscale-image` ก่อนใช้งาน

## สิทธิ์ GHCR

หลัง push ครั้งแรกเปิด GitHub → โปรไฟล์ `kaoitp` → Packages → `yharnam-server-tailscale` → Package settings → Change visibility → Public หากต้องการให้ Unraid pull โดยไม่ล็อกอิน (public เปิดให้ทุกคนอ่าน image ได้) หรือคง Private และล็อกอิน GHCR บน Unraid ด้วยบัญชีที่มีสิทธิ์อ่านและ classic PAT ที่มี `read:packages` ผ่าน `docker login ghcr.io` โดยป้อน token แบบโต้ตอบ ไม่ใส่ใน compose หรือแชต ดู [คู่มือ GitHub](https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility) หาก push ไม่ผ่านให้ตรวจ Settings → Actions → General → Workflow permissions และ Package settings → Manage Actions access ว่า repo นี้เขียน package ได้ GitHub อาจจำกัดการเปลี่ยน visibility กลับหลังเผยแพร่

## ติดตั้งบน Unraid ด้วย Docker template

Template นี้ยังไม่ได้อยู่ในผลค้นหา Community Apps ทั่วไป ต้องนำเข้าเองก่อน ใช้ได้โดยไม่ต้องติดตั้ง Compose บน Unraid x86-64 ที่เปิดใช้งาน Docker:

1. เปิด Terminal ใน Unraid แล้วดาวน์โหลด template โดยคำสั่งนี้จะไม่เขียนทับไฟล์ชื่อเดียวกันที่มีอยู่:

   ```sh
   test ! -e /boot/config/plugins/dockerMan/templates-user/my-Yharnam-Together-Tailscale.xml && \
     curl -fL https://raw.githubusercontent.com/kaoitp/yharnam-server-image/main/templates/yharnam-together-server.xml \
     -o /boot/config/plugins/dockerMan/templates-user/my-Yharnam-Together-Tailscale.xml
   ```

   หากมีไฟล์นี้อยู่แล้ว คำสั่งจะไม่ดาวน์โหลดทับ ให้ตรวจไฟล์เดิมก่อน หากเคยติดตั้ง template รุ่น host network ให้ดาวน์โหลดไฟล์ชื่อใหม่นี้และเลือก template Tailscale; container เดิมจะไม่เปลี่ยนอัตโนมัติ หาก UI มีช่อง Template repositories สามารถเพิ่ม `https://github.com/kaoitp/yharnam-server-image` แทนได้ แล้วเลือกจากรายการ template
2. สร้าง **โฟลเดอร์ข้อมูลใหม่** ใน Unraid terminal และให้สิทธิ์ user ของ image เฉพาะโฟลเดอร์นี้ อย่าใช้กับโฟลเดอร์ที่มีข้อมูลอื่น:

   ```sh
   if [ -e /mnt/user/appdata/yharnam-server ]; then
     echo 'Directory exists; inspect and back up before changing permissions.'
   else
     mkdir -p /mnt/user/appdata/yharnam-server && \
       chown 10001:10001 /mnt/user/appdata/yharnam-server && \
       chmod 750 /mnt/user/appdata/yharnam-server
   fi
   ```

   หากมีข้อมูลอยู่แล้ว ให้ตรวจสิทธิ์และสำรองก่อน ไม่สั่ง `chown -R` โดยไม่ตรวจสอบ `/data` เก็บโลก ฐานข้อมูล การตั้งค่า และ `link_key.bin`; ควรใช้ storage ภายในที่เชื่อถือได้
3. ไปที่ Docker → Add Container → Template แล้วเลือก `Yharnam-Together-Tailscale` (อาจแสดงในกลุ่ม User templates) ตรวจช่อง **Repository** ให้เป็น `ghcr.io/kaoitp/yharnam-server-tailscale:<tag>-ts3` ที่ build สำเร็จและตรงกับ client ทุกคน ค่าเริ่มต้นเป็น `latest` ตรวจ **Server data** ให้ตรงโฟลเดอร์ที่เตรียมไว้ แล้วกด Apply ตรวจ log จากหน้า Docker หลังเริ่ม แล้วตรวจว่า Tailscale เชื่อมต่อจริง หาก hook ล้มเหลวอาจเริ่ม server โดยไม่มี Tailscale
4. ใช้ Unraid 7 หรือใหม่กว่า เปิด **Use Tailscale** ตั้ง hostname ไม่ซ้ำ และใช้ kernel networking (ปิด Tailscale Userspace Networking) จากนั้น Apply และเปิดลิงก์ยืนยันใน log เพื่อเข้าร่วม Tailnet ให้ผู้เล่นใช้ Tailscale และตั้ง IP Tailscale ของ **container** ใน client ไม่ต้องเปิด port บน host; ไม่ต้องเปิด Serve หรือ Funnel. Template ใช้ bridge และไม่ publish port ไปยัง host. ดู [คู่มือ Tailscale ของ Unraid](https://docs.unraid.net/unraid-os/system-administration/secure-your-server/tailscale/)

Template ตั้ง restart policy `unless-stopped` ซึ่งไม่ pull image ใหม่เอง ปิดการอัปเดตอัตโนมัติสำหรับ container นี้ และอย่าใช้ `latest` หากต้องการตรึงรุ่นให้ตรง client เมื่อมีการ pull หรือสร้าง container ใหม่

## สำรอง อัปเดต และย้อนกลับ

ทำหลังทุกคนออกจากเกม:

1. ที่หน้า Docker หยุด `Yharnam-Together-Tailscale` และรอให้หยุดเรียบร้อย เพื่อให้ SQLite และ world journal สอดคล้องกัน
2. คัดลอก **ทั้งโฟลเดอร์ข้อมูล** `/mnt/user/appdata/yharnam-server` รวมไฟล์ซ่อน สิทธิ์ และ `link_key.bin` ไปยัง backup แยกจาก Unraid เก็บค่า Repository/tag หรือ digest และการตั้งค่า template ไว้ด้วย ป้องกันการเข้าถึง backup เพราะมีข้อมูลบัญชี กุญแจ และสถานะ Tailscale ตรวจและทดลองกู้คืนบนเครื่องแยก
3. ตรวจว่า Actions สำหรับรุ่นใหม่สำเร็จและ client ทุกคนใช้รุ่นเดียวกัน จากหน้า Docker เลือก Edit ของ container เปลี่ยน tag ใน Repository แล้ว Apply เพื่อดึงและสร้าง container ใหม่โดยใช้ data path เดิม ตรวจ log ก่อนให้ผู้เล่นเข้า
4. หากย้อนกลับ ให้หยุด container เก็บสำเนาข้อมูลปัจจุบันแยกไว้ แล้วกู้ทั้งโฟลเดอร์จาก backup ก่อนอัปเดต จากนั้น Edit เปลี่ยน Repository กลับเป็น tag เดิมแล้ว Apply การกู้ backup ทำให้ความคืบหน้าหลัง backup หายไป; ข้อมูลที่รุ่นใหม่เขียนแล้วอาจใช้กับรุ่นเก่าไม่ได้ อย่าแทน `link_key.bin` ด้วยกุญแจใหม่ เพราะ client อาจไม่เชื่อถือ server เดิม

หาก log แจ้ง `Can't get Tailscale JSON` ให้ตรวจว่าใช้ image รุ่น `-ts3` หรือ `latest` ที่ pull ใหม่แล้ว: รุ่นนี้บรรจุ Tailscale ไว้ใน image และ hook ควรแสดง `Tailscale found, continuing` จากนั้นตรวจการยืนยัน Tailnet ใน log ห้ามส่ง auth key หรือข้อมูลสถานะ Tailscale ให้ผู้อื่น

การทดสอบใน workflow ใช้ hook และ daemon จริงแบบ userspace โดยไม่เข้าร่วม Tailnet และจำลองการส่งต่อไปยัง server; ยังไม่ยืนยัน kernel networking, การเชื่อม Tailnet, UDP multiplayer หรือ Unraid จริง

+ عددای منفیو بزرگتر از 255 رو باگ میشد درست کردم

+ عددا 64بیتی شدن

+ یونیکد های فارسی و ایموجی اضافه شد

+ متد code units مشکل داشت برای کاراکتر های غیر اسکی اینکودرشو عوض کردم و درست شد

+ همون مشکل عددا توی استرینگ هم بود که رفع شد الان طول متن بیشتری ذخیره میکنه

+ Pdb.open 

+ متدهای get(key) و getAt(index) و عملگرهای ایندکس (pdb[key] و pdb[index])

+  استخراج کامل داده‌ها: all()، toList() و toMap()

+ توابع جستجو : containsKey(key) و contains(value)

+  دریافت متادیتا: length، isEmpty isNotEmpty keys values

+ جایگزینی مقدارعا از طریق set(key, val)، setAt(index, val) (pdb[key] = val و pdb[index] = val)

+ حذف بر اساس کلید یا مقدار  remove(keyOrValue)

+ حذف بر اساس لوکیشن از removeAt(index) برای دیتابیس‌ های LIST

+ سیکتیر کامل دیتابیس با clear()
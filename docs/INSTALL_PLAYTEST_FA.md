# راهنمای نصب Playtest

## فایل ها

- `chogan-vertical-slice-debug.apk`: نسخه پیشنهادی برای نصب و تست.
- `chogan-vertical-slice-release.apk`: نسخه release امضاشده؛ اگر نسخه debug نصب باشد ممکن است به دلیل تفاوت signature نصب نشود.
- `PLAYTEST_FORM_FA.md`: فرم بازخورد انسانی.
- `OWNER_DEVICE_QA_FA.md`: چک لیست سه Run.
- `BUG_REPORT_FA.md`: قالب گزارش خطا.
- `RELEASE_NOTES.md`: خلاصه نسخه.

## نصب

1. APK debug را به گوشی منتقل کنید.
2. نصب از منبع محلی را فقط برای همین فایل تایید کنید.
3. بازی را اجرا کنید.
4. گوشی را در حالت Landscape نگه دارید.
5. یک Run کامل یا حداقل مسیر Tutorial -> Run Map -> Preparation -> Match را تست کنید.

## نکته release

برای نصب release روی دستگاهی که debug نصب دارد، ابتدا باید درباره حذف debug و از دست رفتن save تصمیم گرفته شود.

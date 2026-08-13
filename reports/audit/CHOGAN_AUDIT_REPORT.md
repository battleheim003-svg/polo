# گزارش ممیزی پروتوتایپ Chogan

تاریخ ممیزی: 2026-08-13  
مسیر پروژه: `F:\polo`  
دامنه ممیزی: بازبینی ایستا، اجرای تست Godot، اجرای smoke/headless scene، شبیه سازی 1000 مسابقه، بررسی APK release/debug، بررسی فایل های تحویل.

## 1. رای نهایی

**ITERATE - ابتدا پروتوتایپ اصلاح شود**

هسته شبیه سازی، داده، تست پایه، خروجی Android و بسته تحویل وجود دارد و پروژه به بازطراحی اساسی نیاز ندارد. اما برای Vertical Slice هنوز چند شکاف مهم دارد: آماده سازی/lineup واقعی نیست، خوانایی gameplay کافی نیست، چند مکانیک فقط اسمی یا ناقص اثر می گذارد، و تست ها بخشی از معیارها را سطحی پوشش می دهند.

## 2. امتیاز آمادگی

**68 / 100**

| بخش | امتیاز | توضیح |
|---|---:|---|
| معماری | 13/15 | تفکیک دامنه، autoload و scene flow خوب است؛ اما UI و شبیه سازی هنوز ابزارهای جداسازی/QA کامل ندارند. |
| کامل بودن موتور | 13/20 | 2 چکر، 5 زون، 6 اکشن، AI، stamina/focus و extra time هست؛ ولی line owner، foul، skill، synergy و command effects کامل نیستند. |
| خوانایی gameplay | 7/15 | UI جریان کلی را نشان می دهد، اما چرایی اکشن ها، rider ها، stamina/focus و نقش ها برای بازیکن روشن نیست. |
| determinism/test | 11/15 | تست ها و seed determinism پاس شدند؛ بعضی assertions ضعیف یا غیرمستقیم اند و UI تست ندارد. |
| balance | 7/10 | 1000 match بدون crash/deadlock اجرا شد و win gap زیر 15% است؛ ولی نرخ گل پایین و draw بالا است. |
| UI/flow | 5/10 | menu/prep/match/results وجود دارد؛ prep بیشتر نمایشی است و pause/lineup/role-fit ندارد. |
| Android/performance | 4/5 | APK release امضا و verify شد؛ نصب روی دستگاه و FPS/memory تست نشد. |
| docs/delivery | 8/10 | README/BALANCE/ARCHITECTURE/ANDROID_QA/DELIVERY و zip تحویل هست؛ Git repo و AGENTS/R&D جداگانه نیست. |

## 3. جدول معیارهای پذیرش

| معیار | وضعیت | شاهد |
|---|---|---|
| پروژه در Godot باز/parse می شود | Pass | `--import` و تست headless با exit code 0 |
| main scene شروع می شود | Pass | `boot.tscn --quit-after 5` exit code 0 |
| بازی تا results تمام می شود | Partial | engine و smoke pass؛ تعامل گرافیکی واقعی تست نشد |
| 2 chukkers + extra time | Pass | `BalanceConfig` و `MatchEngine._advance_clock` |
| 5 zone ball model | Pass | `BallState.zone` و UI پنج zone |
| possession و line ownership | Partial | state/UI دارد؛ line owner در dominance اثر عددی ندارد |
| 6 action اصلی | Pass | Strike/Pass/Hook/RideOff/Recovery/Shot در engine |
| foul/free hit | Partial | event دارد؛ probability از control/calmness اثر نمی گیرد |
| skill activation | Partial | event و focus bump دارد؛ skill های متمایز مکانیکی نیستند |
| stamina/focus | Partial | در domain هست؛ در UI خوانا و per-rider نمایش داده نمی شود |
| substitution بین چکرها | Partial | خودکار است؛ تصمیم بازیکن/لیست تعویض ندارد |
| coach command | Partial | اثر +7 دارد؛ JSON effects کامل مصرف نمی شود و duration ندارد |
| AI profiles | Partial | AI تصمیم می گیرد؛ فقط balanced/aggressive در داده دیده شد |
| determinism با seed | Pass | تست `same seed` پاس شد |
| 1000 match sim | Pass | 1000 مسابقه، exit code 0، بدون crash گزارش شده |
| Android release APK | Pass | `apksigner verify` exit code 0 |
| Placeholder/TODO | Partial | TODO جدی نبود؛ placeholder icon/visual باقی است |
| Git hygiene | Not Tested/Fail | مسیر `F:\polo` Git repo نیست |

## 4. پاسخ مستقیم به آمادگی مرحله بعد

آیا برای Vertical Slice آماده است؟ **نه، ابتدا iterate.**  
آیا هسته قابل نجات است؟ **بله.** معماری و engine قابل ادامه اند.  
آیا باید از صفر ساخت؟ **نه.** مشکل ها بیشتر تکمیل مکانیک، UI clarity و تست اند.  
آیا برای ساخت محتوا/آرت/مرحله بعد مناسب است؟ **با احتیاط نه؛** اول باید تصمیم های بازیکن در prep/match و feedback gameplay واقعی تر شود.

## 5. نتایج اجرای واقعی

| اجرا | نتیجه |
|---|---|
| Godot version | `4.7.1.stable.official.a13da4feb` |
| Unit/domain tests | exit code 0، `TESTS PASSED: 20 checks` |
| Smoke runner | exit code 0، `SMOKE PASSED: scene data and match loop are available` |
| Boot scene headless | exit code 0، بدون خطای project runtime |
| Balance simulator | exit code 0، 1000 match |
| Balance result | player win 28.9%، enemy win 39.5%، draw 31.6%، avg goals 0.936، avg length 363.2، fouls 3.237، hooks 10328، passes 12402، ride-offs 8065، skill rate 11.889 |
| Android release verify | exit code 0، APK signature v2/v3 true |
| Android badging | package `com.example.chogan`، version `0.1.0`، min SDK 24، target SDK 36، arm64-v8a/armeabi-v7a |
| Device/emulator test | Not Tested؛ دستگاه/AVD قابل اتکا در دسترس نبود |

هش ها:

| فایل | SHA256 |
|---|---|
| `builds/chogan-debug.apk` | `404A523ABC06855EB462B88DDCFE2797D24135797DA45228D812DA53D03E65EF` |
| `builds/chogan-release.apk` | `EE152353D4F6D8B1AAF30B6F00A7255B35C4B0BB8D11533B9455C498B5462E00` |
| `delivery/chogan-prototype-delivery.zip` | `B331CC0C95B44175E2A39D81A8722C705C785F969EC75819FAA2519E1DF3D94B` |

## 6. ایرادهای بحرانی قبل از Vertical Slice

1. **Preparation واقعی نیست.** بازیکن lineup، نقش ها، role fit، synergy یا اسب را انتخاب/تنظیم نمی کند و بیشتر با ترکیب ثابت وارد بازی می شود.
2. **خوانایی تصمیم ها در match پایین است.** UI نتیجه اکشن را نشان می دهد، اما چرایی، rider فعال، stamina/focus، مزیت خط، و اثر فرمان مربی برای بازیکن واضح نیست.
3. **چند مکانیک هویتی هنوز نیمه کاره است.** line owner در dominance اثر ندارد، foul از control/calmness استفاده نمی کند، skill ها اثر خاص جداگانه ندارند، synergy شرطی/داده محور نیست.
4. **تست ها برای پذیرش vertical slice کافی نیستند.** تست ها پاس می شوند اما بخشی از آن ها false-positive-friendly هستند و UI/flow واقعی تست نشده است.

## 7. ایرادهای مهم غیر بحرانی

- نرخ گل پایین و draw بالا است؛ حس مسابقه ممکن است کند شود.
- فقط دو AI profile در داده فعال است.
- `export_presets.cfg` شامل مسیر/رمز keystore است؛ در صورت Git شدن خطر hygiene/security دارد.
- balance report فعلی action های strike/recovery/shot و breakdown مهارت ها را کامل گزارش نمی کند.
- Android performance روی دستگاه واقعی اندازه گیری نشد.
- generated UI و placeholder visuals برای ارائه رسمی کافی نیستند.

## 8. بدهی فنی و placeholder ها

- `README.md` صریحاً از generated Control nodes و placeholder visuals نام می برد.
- icon اصلی از `assets/placeholder/icon.svg` می آید.
- `.godot`، build outputs، delivery zip و downloads بزرگ در workspace وجود دارند؛ Git repo برای تشخیص tracked/untracked موجود نیست.
- سندهای `README.md`، `ARCHITECTURE.md`، `BALANCE.md`، `CHANGELOG.md`، `docs/ANDROID_QA.md`، `docs/DELIVERY.md` وجود دارند؛ `AGENTS.md` و سند R&D جداگانه پیدا نشد.

## 9. قابلیت های واقعاً کامل

- اجرای deterministic match loop با seed.
- data repository و validation اولیه riders/horses/teams/tactics.
- scene flow پایه menu/preparation/match/results.
- 2 chukker، 5 zone، score، possession، commands و event log.
- save/load پایه با schema version و backup.
- تست های headless و smoke runner.
- Android debug/release export و package delivery.

## 10. قابلیت هایی که حاضرند اما کامل نیستند

- lineup/preparation: نمایش دارد، انتخاب واقعی ندارد.
- tactic/coach command: اثر ساده دارد، نه duration/cooldown و نه مصرف کامل JSON effects.
- skill: activation دارد، skill identity واقعی ندارد.
- foul/free hit: وجود دارد، اما مدل احتمال و اثر طراحی شده کامل نیست.
- AI: کار می کند، اما profile diversity و تصمیم های پیچیده ندارد.
- UI match: state را نشان می دهد، اما readable gameplay هنوز نه.
- balance tooling: 1000 sim دارد، اما گزارش تحلیلی کامل نیست.

## 11. پیشنهاد مسیر بعدی

مسیر پیشنهادی: **prompt to fix prototype**.

دلیل: قبل از ساخت vertical slice، باید همین prototype در سه محور اصلاح شود: تصمیم های واقعی بازیکن در preparation، خوانایی/feedback match، و کامل شدن مکانیک های line/foul/skill/synergy همراه با تست های دقیق تر.

## 12. CHOGAN_PROTOTYPE_AUDIT_PACKET

```text
CHOGAN_PROTOTYPE_AUDIT_PACKET
ProjectPath: F:\polo
GodotVersion: 4.7.1.stable.official.a13da4feb
Verdict: ITERATE - ابتدا پروتوتایپ اصلاح شود
ReadinessScore: 68/100
Tests: PASS, exit code 0, TESTS PASSED: 20 checks
Smoke: PASS, exit code 0
BootSceneHeadless: PASS, exit code 0
BalanceSim: PASS, 1000 matches
BalanceSummary: player_win=0.289, enemy_win=0.395, draw=0.316, avg_goals=0.936, avg_length=363.2, fouls=3.237, hooks=10328, passes=12402, ride_offs=8065, skill_rate=11.889
AndroidRelease: PASS, apksigner verify exit code 0, v2=true, v3=true
ReleaseAPK_SHA256: EE152353D4F6D8B1AAF30B6F00A7255B35C4B0BB8D11533B9455C498B5462E00
DebugAPK_SHA256: 404A523ABC06855EB462B88DDCFE2797D24135797DA45228D812DA53D03E65EF
DeliveryZip_SHA256: B331CC0C95B44175E2A39D81A8722C705C785F969EC75819FAA2519E1DF3D94B
DeviceInstall: NOT_TESTED
GitRepo: NOT_FOUND
CriticalBlockers: prep_not_interactive; gameplay_readability_low; line_foul_skill_synergy_incomplete; tests_not_acceptance_grade
RecommendedNextPath: prompt_to_fix_prototype
```

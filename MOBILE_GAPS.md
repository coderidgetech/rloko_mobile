# Mobile app — gap review (2026-06-21)

End-to-end review of the Flutter consumer app. The core shopping flow (cart →
checkout → order with server-side repricing, real Stripe + COD, addresses,
rewards, wishlist, region/location gate, order tracking/returns) is genuinely
built. Gaps below; `✅` = fixed in branch `fix/mobile-gaps-batch1`.

## 🔴 Security & release-blocking
- ✅ **Real Google Maps API key committed** in `assets/env/app.{dev,local,prod}.env` → scrubbed to placeholders; real keys now only in the git-ignored `assets/env/app.env`, which `main.dart` now loads as an override. **ACTION (you): rotate the Maps key in Google Cloud — it's in git history — and restrict it.**
- **Prod env non-functional** — `app.prod.env`: `API_BASE_URL=https://rloko.com/api` (parked, should be `dev.rloko.com`), ships a test Stripe key, blank Google client IDs (Google sign-in dead). Fix in `app.env` / CI before a prod build.
- **Token refresh likely broken** — `dio_client.dart:154` POSTs `/auth/refresh` with no refresh token / no auth header → silent logouts. Verify the backend refresh contract for mobile.
- **No maintenance-mode gate** — `SiteConfig` has no `maintenanceMode`; backend maintenance won't stop the app.

## 🟠 Functional gaps
- ✅ **`getById` + recommendations missing `?market=`** → now send market (wrong-market PDP fixed).
- ✅ **Search was client-side (first 200 products)** → now uses backend `?search=` (threaded through bloc→usecase→repo→datasource; search page debounces + renders backend results).
- ✅ **PDP dropped real `care`/`brand`/`country_of_origin`** (faked from `details[]`/hardcoded) → now parsed + rendered.
- ✅ **Product variants (color siblings)** — full slice: `getVariants()` repo/usecase/DI + a PDP **colour switcher** (`ProductVariantRow`) that shows sibling thumbnails and opens the tapped colour's PDP.
- **Reviews** — ✅ data layer for **update / delete / helpful** (datasource/repo/usecases/DI) + a **"Helpful" button** on the PDP reviews. Still UI-pending: edit/delete actions on "My Reviews" and review image upload (the data layer is ready/callable).
- **Shipping estimate uses a flat 0.5 lb/item, no dimensions** — checkout estimate can differ from the rate bought at fulfillment (backend uses real weight+dims). Cart entity carries no weight/dims to send.
- **Promo validate sent in USD** — for India the backend reprices in INR → coupon min-purchase/discount preview can mismatch/reject.
- **Filters hardcoded + in-memory** — static color/size lists, USD price buckets even in IN, filters the cached list instead of backend params.
- **No deep links / app links** — password-reset email links, shared product/order links, and notification taps can't open the app.
- **Push doesn't navigate** — `fcm_service.dart` only logs foreground messages; no background/tap/cold-start handling, no local-notification display.
- **No email-verification or in-app password-reset-completion flow.**

## 🟡 Data / polish
- **PDP fakes** size chart, garment measurement, "recommended size"; `badge`/`video_url` parsed but not rendered.
- **Hardcoded FX rates** — `83` display, `75` gift charge; **rewards shows `₹ × 83` always** even for US users.
- **Dead `CheckoutBloc`** (in DI, unused; live `CheckoutPage` re-implements it).
- Home hero/story-circle Unsplash placeholders; videos not shoppable.
- Branding still "Rloco" (Android label, iOS display name) vs Rloko.

## ⚙️ Quality / infra
- **Near-zero tests** (only the region resolver). No bloc/repo/network/auth tests.
- **No mobile CI** (no analyze/test/build pipeline).
- **iOS flavors incomplete** — no `Debug-dev`/`Release-dev` configs; stray unreferenced `.xcconfig` files; `flutter run --flavor dev` fails on iOS.
- **Release signing falls back to the debug keystore** when `key.properties` is absent.

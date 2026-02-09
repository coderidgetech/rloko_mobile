# Hardcoded Data Review

This document lists **hardcoded data** across all pages/features so you can decide what to move to config, API, or constants.

---

## Summary by type

| Type | Where | Recommendation |
|------|--------|----------------|
| **Mock / fake data** | Payment methods, cart coupons, product reviews, rewards points | Replace with API or remove when backend is ready |
| **Contact / support** | Contact page, privacy/terms contact | Move to config or env |
| **Copy / legal** | Terms, privacy, about, help FAQ, size guide | Keep in app or move to CMS/config |
| **UI labels** | All pages | Fine as-is or move to l10n |
| **Numbers / thresholds** | Shipping ₹2000, bundle 10%, trust badges | Move to config or constants |
| **Placeholder content** | Hero slides fallback, search suggestions, story titles | Prefer config/API where available |

---

## 1. Account & Home

### `lib/features/home/presentation/pages/account_page.dart`
- **Version:** `'Version 1.0.0'` — consider from package version.
- **Stats:** Orders and Points show `'—'` (placeholder until API); Wishlist uses bloc.

### `lib/features/home/presentation/pages/contact_page.dart`
- **Contact:** `_email = 'support@rloco.com'`, `_phone = '+91 1800-123-4567'` — **move to config or env.**
- **Copy:** "We typically respond within 24 hours", "Support hours Mon–Sat...", "For returns..." — optional config.

### `lib/features/home/presentation/pages/about_page.dart`
- **Copy:** "Rloco is your destination...", "What we offer" bullets, "Our commitment" — static copy; optional CMS.

### `lib/features/home/presentation/pages/home_page.dart`
- **Hero fallback:** `_defaultHeroSlides()` — "New Season", "Spring Collection 2026", "Designer Bags", "Summer Sale", "Up to 50% Off", links `/new-arrivals`, `/categories`, `/sale`. Used when config has no hero.
- **Hero images:** `_defaultHeroImages` — 3 Unsplash URLs when hero image empty.
- **Trust badges:** `'Free Shipping'` + `'On orders \$50+'`, `'Easy Returns'` + `'30-day policy'`, `'Secure Pay'` + `'100% protected'` — **move thresholds/copy to config.**
- **Footer:** "Download Our App", "Download Now", "Tik Tok" label.
- **Story circles:** Fallback "New", "Sale" with `placeholderImageUrl` when no categories.

---

## 2. Auth & Profile

### `lib/features/auth/presentation/pages/profile_edit_page.dart`
- **Labels:** "Edit Profile", "Full Name", "Email Address", "Phone Number", "Gender", "Date of Birth", "City", "Save Changes", "Tap to change photo" — UI strings (fine or l10n).

### `lib/features/auth/presentation/pages/login_page.dart`
- **Title:** "Welcome Back" — UI.

### `lib/features/auth/presentation/pages/signup_page.dart`
- **Titles:** "Create Account", "Join Rloco today", "Verify OTP", "Resend OTP in ${_countdown}s" — UI.
- **Labels:** "Full Name", etc. — UI.
- **Links:** "Privacy Policy" — UI.

### `lib/features/auth/presentation/pages/forgot_password_page.dart`
- Labels and messages — UI copy.

---

## 3. Payment & Settings

### `lib/features/home/presentation/pages/payment_methods_page.dart`
- **Mock list:** Two hardcoded methods:
  - Card: `id: '1'`, `'**** **** **** 4532'`, `'PRANEETH KUMAR'`, `'12/26'`, default.
  - UPI: `id: '2'`, `'praneeth@paytm'`.
- **Copy:** "Your payment information is encrypted... We never store your CVV" — static.
- **Recommendation:** Replace list with real API when saved-payment-methods endpoint exists.

### `lib/features/home/presentation/pages/add_payment_method_page.dart`
- **Title:** "Add Payment Method", "Card Number", "Cardholder Name", "Expiry Date", "100% Secure & Encrypted" — UI / static.

### `lib/features/home/presentation/pages/settings_page.dart`
- **Items:** "Change Password", "Language" — UI (links to real screens).

### `lib/features/home/presentation/pages/change_password_page.dart`
- **Title:** "Change Password" — UI.

### `lib/features/home/presentation/pages/language_page.dart`
- **Options:** "English", "Hindi" — UI; selection is local state only (no backend).

---

## 4. Cart

### `lib/features/cart/presentation/pages/cart_page.dart`
- **Mock coupons:** `_couponCodes = {'RLOCO10': 10, 'SAVE20': 20, 'WELCOME15': 15}` — **replace with promotions API** (e.g. same as Coupons page).
- **Labels:** "Apply Coupon", "Start Shopping", "Invalid coupon code", etc. — UI.

---

## 5. Product & Search

### `lib/features/product/presentation/pages/product_detail_page.dart`
- **Garment measurement:** `'Garment Measurement: Chest 41.0in'` — **should come from product/size data or API**, not fixed.
- **Delivery card:** `crossed: '₹2099'`, `price: '₹671 (68% OFF)'`, `subtitle: '₹10 additional fee applicable'` — **replace with real pricing/shipping logic.**
- **Product details fallbacks:** `'100% Cotton'` when material empty, `'Machine Wash'`, `'Country of Origin', 'USA'` — **prefer product/API or constants.**
- **Reviews:** Three hardcoded reviews:
  - `'Sarah M.'`, 5 stars, "Absolutely love this piece!..."
  - `'Emma R.'`, 5 stars, "Great product!..."
  - `'Jessica L.'`, 4 stars, "Beautiful design..."
- **Recommendation:** Use real reviews API; if none, show empty state or single “No reviews yet” message.
- **Bundle:** `'Bundle Discount (10%)'`, `'One Size'` for bundle add-to-cart — 10% could be config; "One Size" is fallback when product has no size.
- **Section titles:** "Product Details", "Customer Reviews", "You May Also Like", "Similar Products", "Trending Now", "View All" — UI.
- **SKU:** `'RL-${product.id}'` — format may be backend-driven.

### `lib/features/product/presentation/pages/search_page.dart`
- **Trending:** `_trendingSearches = ['Dresses', 'Summer Collection', 'Designer Bags', 'Sneakers', 'Jewelry', 'Sale Items']` — **move to config or API.**
- **Categories:** `_categories` — Women, Men, Dresses, Shoes, Bags, Jewelry with links — **prefer from category API/config.**

### `lib/features/product/presentation/pages/product_list_page.dart`
- **Banner:** "Limited Time Offer" — optional config.
- **Sort options:** "Newest First", etc. — UI (can stay).

### `lib/features/product/presentation/pages/category_products_page.dart`
- **Title fallback:** `'All Products'` when no category — UI.

### `lib/features/product/presentation/pages/categories_page.dart`
- **Button:** "Search All Products" — UI.

---

## 6. Orders & Checkout

### `lib/features/order/presentation/pages/orders_page.dart`
- **Title:** "My Orders", "All Orders" — UI.

### `lib/features/order/presentation/pages/order_detail_page.dart`
- **Titles:** "Order Details", "Estimated Delivery", "Order Items", "Shipping Address", "Payment Method", "Order Summary", "Contact Support", "Download Invoice" — UI.

### `lib/features/order/presentation/pages/checkout_page.dart`
- **Labels:** "Select Delivery Address", "Add New Address", "Delivery Address" — UI.

### `lib/features/order/presentation/pages/order_confirmation_page.dart`
- **Labels:** "Order confirmed", "Back to home", "View order", "Continue shopping" — UI.

---

## 7. Address & Delivery

### `lib/features/address/presentation/pages/addresses_page.dart`
- **Title:** "Saved Addresses", "Add New Address" — UI.

### `lib/features/address/presentation/pages/address_form_page.dart`
- **Titles:** "Edit Address" / "Add New Address", "Delivery Details", "Address Type", "Full Name *", "Phone Number *", "Street Address *", "Save Address" — UI.

### `lib/features/home/presentation/pages/delivery_location_page.dart`
- **Titles:** "Select Delivery Location", "Use Current Location", "Saved Addresses", "Add New" — UI.
- **Copy:** "Free shipping on orders over ₹2000" — **move to constants/config** (same as shipping page).

### `lib/features/home/presentation/pages/shipping_info_page.dart`
- **Facts:** "Free Shipping" + "On orders over ₹2000", "5-7 Days", "30-Day Returns", "Secure Packaging" — **₹2000 and copy to config/constants.**
- **Copy:** "Standard delivery: 5-7 business days. Free shipping on orders over ₹2000.", "Delivery Locations", "Order Processing" bullets — static; optional config.

---

## 8. Help, Legal & Info

### `lib/features/home/presentation/pages/help_center_page.dart`
- **FAQ:** Six Q&A pairs (track order, return policy, change/cancel order, payment methods, coupon use, international shipping) — **optional config/CMS.**
- **Section cards:** "Track your order", "Returns & Refunds", "Shipping information" with action labels — UI.

### `lib/features/home/presentation/pages/terms_page.dart`
- **Sections:** 10 terms sections (acceptance, use, account, products, shipping, returns, IP, disclaimer, governing law, changes) — legal copy; optional CMS.
- **Last updated:** "January 2025" — **make dynamic or config.**

### `lib/features/home/presentation/pages/privacy_page.dart`
- **Sections:** 9 privacy sections — legal copy; optional CMS.
- **Contact:** "support@rloco.com" in Contact section — **align with contact page (config).**
- **Last updated:** "January 2025" — **make dynamic or config.**

### `lib/features/home/presentation/pages/size_guide_page.dart`
- **Tables:** Men's tops, women's tops, footwear (all measurement strings) — **optional config/CMS** if sizes vary by brand/category.

---

## 9. Rewards, Coupons, Returns, Notifications

### `lib/features/home/presentation/pages/rewards_page.dart`
- **Points:** `'450'` — **replace with rewards/points API.**
- **Copy:** "Earn points on every order", "Shop to earn more points..." — UI or config.

### `lib/features/home/presentation/pages/coupons_page.dart`
- **Data:** From promotions API (no mock list); labels "Active Coupons", "Expired Coupons", "How to use coupons" — UI.
- **Currency:** Uses `₹` for min order / value from API — ensure consistent with app currency.

### `lib/features/home/presentation/pages/returns_page.dart`
- **Steps:** Four return steps (initiate, ship back, we process, get refund) — copy; one uses `DeliveryConstants.returnInspectionDays`.
- **Titles:** "Easy Returns", "30-day hassle-free", "Return Policy", "Refund Timeline", "My Returns", "Need Help?", "Contact Support" — UI/copy.

### `lib/features/home/presentation/pages/notifications_page.dart`
- **Preferences:** Keys and defaults in SharedPreferences; "Order updates", "Promotions & offers", "New arrivals" — UI.
- **Empty state:** "No notifications yet" — UI.

---

## 10. Router & Config

### `lib/app/router/app_router.dart`
- **Route titles:** "All Products", "New Arrivals", "On Sale", "Highest Discount" — UI for product list routes.

---

## 11. Core / Shared

### `lib/core/constants/delivery_constants.dart`
- **Return inspection:** Used in returns page — keep in constants.

### `lib/core/constants/form_hints.dart`
- **Hints:** "Enter ZIP or postal code", "Enter UPI ID", etc. — UI; keep or l10n.

### `lib/core/widgets/safe_network_image.dart`
- **Placeholder URL:** `placeholderImageUrl` (picsum) and known-broken IDs — technical; keep.

### `lib/core/models/country.dart`
- **Country list:** Full list of countries with codes, names, dial codes, flags — **acceptable as static data** or replace with API.

### `lib/features/config/domain/entities/site_config.dart`
- **Defaults:** Fallback values for design (e.g. 'Inter', '16', '1920') when config missing — keep as defaults.

---

## Recommended next steps

1. **High impact (replace with API or config):**
   - Contact email/phone → config or env.
   - Payment methods list → saved-payment-methods API.
   - Cart coupon codes → use promotions API (like Coupons page).
   - Product detail: delivery prices (₹2099, ₹671, ₹10), garment measurement, product detail fallbacks (material, care, country).
   - Product detail: replace 3 fake reviews with reviews API or empty state.
   - Rewards page: points value from rewards API.
   - Shipping/returns threshold (e.g. ₹2000) and trust-badge copy → config or constants.

2. **Medium (optional config/CMS):**
   - Hero fallback slides and trust badges (home).
   - Search trending + category links.
   - Help FAQ, terms/privacy text, size guide tables.
   - "Last updated" for terms/privacy.

3. **Low (keep or l10n later):**
   - All other UI labels and button text.
   - Version string (or derive from package).

If you tell me which area you want to tackle first (e.g. contact info, payment methods, product detail, rewards), I can suggest concrete code changes and where to add config/API calls.

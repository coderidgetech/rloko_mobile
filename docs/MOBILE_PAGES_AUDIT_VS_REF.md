# Mobile Pages Audit vs Reference (Rloco Final Design 2)

This document compares the Flutter mobile app pages with the React reference project so changes and alignment are tracked.

---

## Already aligned with reference

### 1. **Home** (`HomePage` / `MobileHomePage.tsx`)
- Delivery address bar below header (ref: second row of MobileHomeHeader).
- Hero carousel, quick stats (Trending / New In / Sale), shop-by-category, product sections, trust badges, footer.
- Bottom nav: index 0.
- Fix applied: Home no longer overwrites category list when navigating from Home to Category (only re-requests home sections when Home is the current route).

### 2. **Categories** (`CategoriesPage` / `MobileCategoriesPage.tsx`)
- 2-column grid of category cards (aspect 3:4), same static list (All Products, Women, Men, New Arrivals, Sale, Dresses, Shoes, Bags, Jewelry, Cosmetics).
- Page title: "Categories" + "Tap to explore collections".
- Tap category with subcategories: in-page overlay (expand/collapse), not modal; chevron rotates when expanded.
- Bottom sheet panel: handle bar, "X Collections", 2-col grid of subcategory rows; tap subcategory → navigate and close.
- Bottom nav: index 1.

### 3. **Category products** (`CategoryProductsPage` / `MobileCategoryPage.tsx`)
- QuickCategorySwitcher below header (horizontal pills: Women, Men, New, Sale, Dresses, etc.).
- Filter bar: "Showing X products" + Filter and Sort buttons (rounded, border); subcategory pills when gender && !category (border, shadow).
- Product grid 2 cols; empty state with "Clear Filters".
- Bottom nav: index 1 (Categories tab).
- Fix applied: Empty screen when opening from Home fixed (home no longer dispatches LoadHomeSections when not current route).

### 4. **Bottom navigation** (`BottomNav` / `BottomNavigation.tsx`)
- Custom bar: height 64px, icons 22px, labels 10px; active = primary + top indicator line; cart badge; safe area bottom.
- Same 5 items: Home, Categories, Search, Account, Cart.

### 5. **Account** (`AccountPage` / `MobileAccountPage.tsx`)
- Guest: icon, "Welcome to Rloco", Sign In / Create Account, "Browse as Guest" (Continue Shopping, Help Center).
- Logged-in: profile section (avatar, name), menu rows (Orders, Wishlist, Addresses, Payment, etc.), Log out.
- Bottom nav: index 3.

### 6. **Cart** (`CartPage` / `MobileCartPage.tsx`)
- Uses coupon codes (RLOCO10, SAVE20, WELCOME15); item rows with image, quantity controls, remove, move to wishlist.
- Flutter extends to full checkout (address, payment, place order); ref is cart + coupon only.
- Bottom nav: index 4.

### 7. **Wishlist** (`WishlistPage` / `MobileWishlistPage.tsx`)
- 2-col grid, card with image (aspect 3:4), remove button, name, price, "Add to Cart".
- Empty state and error/sign-in state.
- Bottom nav added so bar is visible (index 0 when on Wishlist, as it’s not a tab).

### 8. **Search** (`SearchPage` / `MobileSearchPage.tsx`)
- Search bar (rounded, bg-foreground/5), Cancel; when empty: recent + trending + category chips; when query: product grid.
- Bottom nav added: index 2.

---

## Bottom nav usage (tab index)

| Route / Page       | Ref              | Flutter currentIndex |
|--------------------|------------------|----------------------|
| `/` Home           | home             | 0                    |
| `/categories`      | categories       | 1                    |
| `/category/...`    | (categories)     | 1                    |
| `/search`          | search           | 2                    |
| `/account`         | account          | 3                    |
| `/cart`            | cart             | 4                    |
| `/wishlist`        | (no tab)         | 0 (bar visible)      |

---

## Optional / minor differences

- **Header**: Ref uses `MobileSubPageHeader` with optional delivery row; Flutter uses `AppHeader` (no delivery row except on Home). Sub-pages (Category, Search, Cart, etc.) could later add a configurable delivery bar if desired.
- **Product detail**: Ref has `MobileProductDetailPage`; Flutter has `ProductDetailPage` (layout and CTA may differ in details).
- **All Products / New Arrivals / Sale**: Implemented as `ProductListPage` with different load events; ref has dedicated mobile pages (e.g. `MobileNewArrivalsPage`, `MobileSalePage`). Functionality aligned; visual tweaks possible.
- **Login / Signup / Forgot password**: Ref has mobile-specific layouts; Flutter uses shared/auth pages. Behavior aligned.
- **Orders, Addresses, Settings, etc.**: Both have equivalent routes; Flutter may have different layout or copy in places.

---

## Cleanup done

- Debug prints removed from: `CategoryProductsPage`, `ProductListBloc`, `ProductRemoteDataSource`.
- `BottomNav` added to: `SearchPage` (index 2), `WishlistPage` (index 0).

---

## Reference paths (React)

- Mobile pages: `Rloco Final Design 2/src/app/pages/mobile/*.tsx`
- Shared mobile components: `Rloco Final Design 2/src/app/components/mobile/*.tsx`
- Key ref files: `MobileHomePage.tsx`, `MobileCategoriesPage.tsx`, `MobileCategoryPage.tsx`, `MobileSubPageHeader.tsx`, `BottomNavigation.tsx`, `MobileSearchPage.tsx`, `MobileCartPage.tsx`, `MobileWishlistPage.tsx`, `MobileAccountPage.tsx`.

# Flutter vs React Mobile – Pin-to-Pin Page Checklist

Use this list to verify each Flutter page matches the corresponding React mobile design.

## ✅ Done
- [x] **Wishlist** – 2-col grid, card rounded-2xl, image aspect 3/4, Trash top-right, Add to Cart rounded-full
- [x] **Cart** – Item layout (96×128 image), quantity circles, Move to Wishlist (heart), Trash, coupon section, fixed bottom summary
- [x] **Product detail** – Full-bleed image, swipe, dots, rating badge, thumbnails, Buy Now + Add to Bag, Delivery & Services, accordions, recommendations, wishlist heart on image
- [x] **Product grid tile** – Pin-to-pin with MobileProductGrid: aspect 3/4 image, rounded-2xl (16px), wishlist top-right w-8 h-8, SALE/NEW badges, rating, name line-clamp-2, category uppercase, price (primary color)
- [x] **ProductListPage** (New Arrivals, Sale, All Products) – Filter pills, stats bar, Sort bottom sheet, sale banner (Sale), empty state with Sparkles (New Arrivals)
- [x] **CategoryProductsPage** – Subcategory pills, stats bar, QuickActions (Filter+Sort), Sort/Filter bottom sheets
- [x] **Sort/Filter bottom sheets** – rounded-t-3xl, handle bar, barrier black/40

## 📋 To verify / align

### Core shopping
| # | Flutter page / route | React reference | Notes |
|---|------------------------|-----------------|--------|
| 1 | HomePage `/` | Mobile home / MobileSubPageHeader + sections | Hero, categories, featured, new, sale, etc. |
| 2 | ProductDetailPage `/product/:id` | MobileProductDetailPage | Already updated; spot-check |
| 3 | CartPage `/cart` | MobileCartPage | Already updated; spot-check |
| 4 | WishlistPage `/wishlist` | MobileWishlistPage | Done above |
| 5 | ProductListPage (all-products, new-arrivals, sale) | MobileAllProductsPage, etc. | Grid 2-col, wishlist on tile |
| 6 | CategoryProductsPage `/category/:gender/:slug` | MobileCategoryPage | Grid + header |
| 7 | SearchPage `/search` | MobileSearchPage | Search bar + grid |
| 8 | CategoriesPage `/categories` | MobileCategoriesPage | Category list / grid |

### Account & profile
| # | Flutter | React | Notes |
|---|---------|--------|--------|
| 9 | AccountPage `/account` | MobileAccountPage | Menu items, layout |
| 10 | ProfileEditPage `/profile/edit` | MobileProfileEditPage | Form fields |
| 11 | AddressesPage `/addresses` | MobileAddressesPage | List + add |
| 12 | AddressFormPage (add/edit) | AddAddressPage (`pages/AddAddressPage.tsx`) | Form |
| 13 | PaymentMethodsPage `/payment-methods` | MobilePaymentMethodsPage | Cards list |
| 14 | AddPaymentMethodPage | MobileAddPaymentMethodPage | Form |

### Orders & checkout
| # | Flutter | React | Notes |
|---|---------|--------|--------|
| 15 | OrdersPage `/orders` | MobileOrdersPage | Order list cards |
| 16 | OrderDetailPage `/orders/:id` | MobileOrderDetailPage | Status, items, tracking |
| 17 | CheckoutPage `/checkout` | MobilePaymentPage / flow | Steps, address, payment |
| 18 | OrderConfirmationPage | MobileOrderConfirmationPage | Success UI |

### Settings & info
| # | Flutter | React | Notes |
|---|---------|--------|--------|
| 19 | DeliveryLocationPage `/delivery-location` | DeliveryLocationPage | Address / pincode |
| 20 | CouponsPage `/coupons` | MobileCouponsPage | Promo list |
| 21 | ReturnsPage `/returns` | MobileReturnsPage | Returns list + policy |
| 22 | ShippingInfoPage `/shipping` | MobileShippingPage | Methods / info |
| 23 | SettingsPage `/settings` | MobileSettingsPage | Toggles / links |
| 24 | NotificationsPage | MobileNotificationsPage | List |
| 25 | ChangePasswordPage | MobileChangePasswordPage | Form |
| 26 | LanguagePage | MobileLanguagePage | Options |
| 27 | ReviewsPage | MobileReviewsPage | Reviews list |
| 28 | RewardsPage | MobileRewardsPage | Rewards UI |
| 29 | AboutPage `/about` | MobileAboutPage | Content |
| 30 | ContactPage `/contact` | MobileContactPage | Form / info |

### Auth & onboarding
| # | Flutter | React | Notes |
|---|---------|--------|--------|
| 31 | SplashPage | MobileSplashScreen | Logo, delay |
| 32 | OnboardingPage | MobileOnboardingPage | Slides |
| 33 | LoginPage | MobileLoginPage | Form |
| 34 | SignupPage | MobileSignupPage | Form |
| 35 | ForgotPasswordPage | MobileForgotPasswordPage | Form |

### Static / other
| # | Flutter | React | Notes |
|---|---------|--------|--------|
| 36 | StaticContentPage (help, terms, privacy, size-guide) | MobileHelpPage, Terms, Privacy, SizeGuide | Title + body |
| 37 | NotFoundPage | MobileNotFoundPage | 404 UI |

---

**How to use:** Pick one row, open the React mobile page and the Flutter page side by side, and adjust layout, spacing, typography, and actions until they match pin-to-pin.

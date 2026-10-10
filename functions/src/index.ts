import {initializeApp} from "firebase-admin/app";
import {setGlobalOptions} from "firebase-functions";

initializeApp();

setGlobalOptions({
  maxInstances: 10,
  region: "europe-west1",
});

export {
  confirmCashPayment,
  createBookingPayment,
  createSubscriptionCheckout,
  getShopPaymentOptions,
  paymobWebhook,
  paymentReturn,
  refreshPaymentStatus,
  setPayoutDestination,
} from "./payment/callables";

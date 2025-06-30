const functions = require("firebase-functions");
const express = require("express");
const bodyParser = require("body-parser");
const { stripe, endpointSecret } = require("./utils/stripe");

const app = express();

// ===============================
// ✅ Route de test (pas de vérification de signature)
// ===============================
app.use("/stripeWebhook-test", bodyParser.json());

app.post("/stripeWebhook-test", (req, res) => {
  const event = req.body;

  console.log("✅ [TEST] Webhook reçu :", event.type);

  if (event.type === "payment_intent.succeeded") {
    const paymentIntent = event.data.object;
    console.log("💰 [TEST] Paiement réussi :", paymentIntent.id);
  }

  res.sendStatus(200);
});

// ===============================
// ✅ Route sécurisée (production)
// ===============================
app.use("/stripeWebhook", bodyParser.raw({ type: "application/json" }));

app.post("/stripeWebhook", (req, res) => {
  const sig = req.headers["stripe-signature"];
  let event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, endpointSecret);
  } catch (err) {
    console.error("❌ Signature invalide :", err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  console.log("🔐 [PROD] Webhook vérifié :", event.type);

  if (event.type === "payment_intent.succeeded") {
    const paymentIntent = event.data.object;
    console.log("💰 [PROD] Paiement réussi :", paymentIntent.id);
  }

  res.sendStatus(200);
});

exports.stripeWebhook = functions.https.onRequest(app);

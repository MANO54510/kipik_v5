require('dotenv').config(); // Toujours en premier

const Stripe = require('stripe');

const stripe = Stripe(process.env.STRIPE_SECRET_KEY);
const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET;

module.exports = {
  stripe,
  endpointSecret,
};
